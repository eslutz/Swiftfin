#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Bootstrap the net-new "Swiftfin visionOS" application target by mirroring the
# existing "Swiftfin tvOS" target. Idempotent-guarded; safe to dry-run on a copy.
#
# Why a script: the project uses Xcode 16 file-system synchronized groups, and
# this wires the visionOS target to compile `Shared/` + `Swiftfin visionOS/`
# (NOT the iOS `Swiftfin/` tree) with the correct SPM products, build settings,
# and synchronized-group membership — reproducibly and reviewably.
#
# Usage:
#   gem install xcodeproj            # once (>= 1.27 supports synchronized groups)
#   ruby Documentation/visionos/bootstrap-target.rb Swiftfin.xcodeproj
#
# CAVEATS:
#   * xcodeproj rewrites project.pbxproj in its own formatting. If you normally
#     edit the project in Xcode, expect a one-time reformat diff; let Xcode
#     re-normalize on the next save if desired.
#   * The resulting visionOS scheme will NOT build until the `Shared/`
#     visionOS-incompatibilities are resolved and the forked view layer exists
#     (see xcode-target-setup.md §4 and the cross-platform validation register).
#   * Author the layered app icon, device icons, and cinema environment
#     separately (binary assets) — see xcode-target-setup.md §5.

require 'xcodeproj'

proj_path = ARGV[0] || 'Swiftfin.xcodeproj'
proj = Xcodeproj::Project.open(proj_path)

if proj.targets.any? { |t| t.name == 'Swiftfin visionOS' }
  abort "‘Swiftfin visionOS’ target already exists — nothing to do."
end
tv  = proj.targets.find { |t| t.name == 'Swiftfin tvOS' } or abort 'no “Swiftfin tvOS” target'
ios = proj.targets.find { |t| t.name == 'Swiftfin iOS' }  or abort 'no “Swiftfin iOS” target'

# SPM products visionOS should link. Excludes VLCUI, CollectionHStack/VGrid,
# Mantis, TVOSPicker, LNPopup* (UIKit/platform-specific or VLC). NOTE: the build
# may reveal additional Shared dependencies (e.g. Engine) — add them as flagged.
WANT = %w[
  CoreStore Defaults Algorithms Nuke NukeUI BlurHashKit Factory Files Pulse
  PulseLogHandler PulseUI OrderedCollections PreferencesView SwiftUIIntrospect
  Engine KeychainSwift IdentifiedCollections StatefulMacros JellyfinAPI
].freeze

# 1) Native application target
t = proj.new(Xcodeproj::Project::Object::PBXNativeTarget)
t.name = 'Swiftfin visionOS'
t.product_name = 'Swiftfin visionOS'
t.product_type = 'com.apple.product-type.application'
proj.targets << t
t.product_reference = proj.products_group.new_product_ref_for_target('Swiftfin visionOS', :application)

# 2) Build configurations mirrored from tvOS, with visionOS overrides
cl = proj.new(Xcodeproj::Project::Object::XCConfigurationList)
cl.default_configuration_is_visible = '0'
cl.default_configuration_name = 'Release'
t.build_configuration_list = cl
tv.build_configuration_list.build_configurations.each do |tvc|
  c = proj.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  c.name = tvc.name
  c.build_settings = tvc.build_settings.dup
  bs = c.build_settings
  bs.delete('TVOS_DEPLOYMENT_TARGET')
  bs['SDKROOT'] = 'xros'
  bs['SUPPORTED_PLATFORMS'] = 'xros xrsimulator'
  bs['XROS_DEPLOYMENT_TARGET'] = '2.0'
  bs['TARGETED_DEVICE_FAMILY'] = '7'
  bs['INFOPLIST_FILE'] = 'Swiftfin visionOS/Resources/Info.plist'
  # Set once the layered icon exists (see setup guide §5):
  # bs['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon-primary-primary'
  cl.build_configurations << c
end

# 3) Synchronized groups: new "Swiftfin visionOS" root group + reuse Shared/Translations/XcodeConfig
vg = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
vg.path = 'Swiftfin visionOS'
vg.source_tree = '<group>'
proj.main_group.children << vg
ex = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
ex.target = t
ex.membership_exceptions = ['Resources/Info.plist'] # handled as the target Info.plist
vg.exceptions << ex
by_name = ->(n) { proj.main_group.children.find { |c| c.respond_to?(:display_name) && c.display_name == n } }
[by_name['Shared'], vg, by_name['Translations'], by_name['XcodeConfig']].compact.each do |g|
  t.file_system_synchronized_groups << g
end

# 4) Build phases: Sources / Frameworks / Resources + tvOS shell-script phases
t.build_phases << proj.new(Xcodeproj::Project::Object::PBXSourcesBuildPhase)
fw = proj.new(Xcodeproj::Project::Object::PBXFrameworksBuildPhase); t.build_phases << fw
t.build_phases << proj.new(Xcodeproj::Project::Object::PBXResourcesBuildPhase)
tv.build_phases.select { |p| p.isa == 'PBXShellScriptBuildPhase' }.each do |sp|
  np = proj.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
  np.name = sp.name
  np.shell_script = sp.shell_script
  np.shell_path = sp.shell_path
  np.input_paths = sp.input_paths.dup
  np.output_paths = sp.output_paths.dup
  t.build_phases.unshift(np)
end

# 5) SPM product dependencies (mirror iOS, filtered to WANT, de-duplicated)
seen = {}
ios.package_product_dependencies.each do |dep|
  next unless WANT.include?(dep.product_name)
  next if seen[dep.product_name]
  seen[dep.product_name] = true
  nd = proj.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
  nd.package = dep.package
  nd.product_name = dep.product_name
  t.package_product_dependencies << nd
  bf = proj.new(Xcodeproj::Project::Object::PBXBuildFile)
  bf.product_ref = nd
  fw.files << bf
end

proj.save
puts "Created ‘Swiftfin visionOS’ → groups: #{t.file_system_synchronized_groups.map(&:display_name).join(', ')}"
puts "  configs: #{cl.build_configurations.map(&:name).join(', ')}; SPM products linked: #{seen.size}"
puts 'Next: add a shared scheme, then resolve Shared/ visionOS-incompatibilities (setup guide §4).'

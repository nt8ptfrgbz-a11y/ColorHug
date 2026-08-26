# frozen_string_literal: true

require 'pathname'

cocoapods_library_paths = Dir[
  '/opt/homebrew/Cellar/cocoapods/*/libexec/gems/*/lib',
]
$LOAD_PATH.unshift(*cocoapods_library_paths)
require 'xcodeproj'

repo_root = Pathname.new(__dir__).parent.expand_path
runner_path = repo_root.join('ios/Runner.xcodeproj')
unity_path = repo_root.join('ios/unityLibrary/Unity-iPhone.xcodeproj')

abort("Missing Unity iOS export: #{unity_path}") unless unity_path.exist?

runner_project = Xcodeproj::Project.open(runner_path)
unity_project = Xcodeproj::Project.open(unity_path)
runner_target = runner_project.targets.find { |target| target.name == 'Runner' }
unity_target = unity_project.targets.find { |target| target.name == 'UnityFramework' }

abort('Runner target was not found') unless runner_target
abort('UnityFramework target was not found') unless unity_target

unity_reference = runner_project.files.find do |reference|
  reference.path&.end_with?('unityLibrary/Unity-iPhone.xcodeproj')
end
unity_reference ||= runner_project.main_group.new_reference(unity_path)

runner_target.add_dependency(unity_target)

# Remove the legacy prebuilt framework reference used before the Unity Xcode
# project was linked. Keeping both makes Xcode copy UnityFramework twice.
legacy_frameworks = runner_project.files.select do |reference|
  reference.path&.end_with?('unityLibrary/UnityFramework.framework')
end
legacy_frameworks.each do |reference|
  runner_target.build_phases.each do |phase|
    next unless phase.respond_to?(:files)

    phase.files.select { |file| file.file_ref == reference }.each(&:remove_from_project)
  end
  reference.remove_from_project
end

frameworks_group = runner_project.frameworks_group
framework_reference = frameworks_group.files.find do |reference|
  reference.path == 'UnityFramework.framework'
end
framework_reference ||= frameworks_group.new_reference(
  'UnityFramework.framework',
  :built_products,
)
framework_reference.path = 'UnityFramework.framework'
framework_reference.source_tree = 'BUILT_PRODUCTS_DIR'
framework_reference.set_explicit_file_type('wrapper.framework')

unless runner_target.frameworks_build_phase.files_references.include?(framework_reference)
  runner_target.frameworks_build_phase.add_file_reference(framework_reference, true)
end

embed_phase = runner_target.copy_files_build_phases.find do |phase|
  phase.name == 'Embed Frameworks'
end
embed_phase ||= runner_target.new_copy_files_build_phase('Embed Frameworks')
embed_phase.dst_subfolder_spec = '10'

embed_build_file = embed_phase.files.find do |file|
  file.file_ref == framework_reference
end
embed_build_file ||= embed_phase.add_file_reference(framework_reference, true)
embed_build_file.settings = {
  'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'],
}

thin_binary_index = runner_target.build_phases.index do |phase|
  phase.respond_to?(:name) && phase.name == 'Thin Binary'
end
if thin_binary_index
  runner_target.build_phases.delete(embed_phase)
  thin_binary_index = runner_target.build_phases.index do |phase|
    phase.respond_to?(:name) && phase.name == 'Thin Binary'
  end
  runner_target.build_phases.insert(thin_binary_index, embed_phase)
end

runner_project.save
puts 'Linked Runner -> UnityFramework and configured Embed Frameworks.'

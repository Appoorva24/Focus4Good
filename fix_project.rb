require 'xcodeproj'
project_path = 'Focus4Good.xcodeproj'
project = Xcodeproj::Project.open(project_path)

files_to_remove = [
  'Focus4Good/Views/Calm/ASMRPlayerView.swift',
  'Focus4Good/Views/Calm/SensorySootheView.swift',
  'Focus4Good/Views/Calm/DeepFocusBrowseView.swift',
  'Focus4Good/Views/Calm/JPMRSessionView.swift',
  'Focus4Good/Views/Calm/BreatheSessionView.swift'
]

def full_path(file_ref)
  file_ref.real_path.to_s
rescue
  file_ref.path.to_s
end

project.targets.each do |target|
  target.source_build_phase.files_references.each do |file_ref|
    next unless file_ref.is_a?(Xcodeproj::Project::Object::PBXFileReference)
    path = full_path(file_ref)
    if files_to_remove.any? { |f| path.end_with?(f) }
      puts "Target #{target.name}: Removing from build phase: #{path}"
      target.source_build_phase.remove_file_reference(file_ref)
    end
  end
end

project.files.each do |file_ref|
  path = full_path(file_ref)
  if files_to_remove.any? { |f| path.end_with?(f) }
    puts "Removing file reference: #{path}"
    file_ref.remove_from_project
  end
end

project.save
puts "Saved project."

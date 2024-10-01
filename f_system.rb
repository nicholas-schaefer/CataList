# interactions with the filesystem
class Fsystem
  def data_images_profiles_path
    File.expand_path("../data/images/profiles", __FILE__)
  end

  def delete_all_file_system_images
    file_system_image_names = get_all_file_system_image_names

    file_system_image_names.each do |fname|
      fpath = File.join(data_images_profiles_path, fname)
      File.delete(fpath)
    end
  end

  def delete_file_system_image(image_basename:)
    fpath = File.join(data_images_profiles_path, image_basename)
    File.delete(fpath)
  end


  private
  def get_all_file_system_image_names
    dir = data_images_profiles_path

    # Ensure the directory exists
    return [] unless Dir.exist?(dir)

    # Get all entries in the directory, filter out subdirectories and special entries
    paths =
      (Dir.entries(dir).select do |entry|
        next if entry == '.' || entry == '..' # Skip current and parent directory
        file_path = File.join(dir, entry)
        File.file?(file_path) # Include only files
      end)
  end
end

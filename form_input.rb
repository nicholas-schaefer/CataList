# Sanitize and validate Contact Form inputs
class FormInput
  def sanitize_field_first_name(input)
    input.strip.downcase
  end

  def sanitize_field_last_name(input)
    input.strip.downcase
  end

  def sanitize_field_phone_number(input)
    input.strip
  end

  def sanitize_field_email(input)
    input.strip
  end

  def sanitize_field_note(input)
    input.strip
  end

  def acceptable_image_type?(file_type)
    case file_type
    when 'image/jpeg' then 'jpg'
    when 'image/png' then 'png'
    else
      false
    end
  end
end

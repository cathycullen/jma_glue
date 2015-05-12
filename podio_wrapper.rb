class PodioWrapper
  def initialize(db_name)
    @config = app_config(db_name)
  end

  def app_config(db_name)
    if db_name == "cheetah"
      {app_id: ENV['PODIO_CHEETAH_CALL_LOG_APP_ID'],
       contact_space: ENV['PODIO_CHEETAH_CONTACT_SPACE']}
    else
      {app_id: ENV['PODIO_JMA_CALL_LOG_APP_ID'],
       contact_space: ENV['PODIO_JMA_CONTACT_SPACE']}
    end
  end

  def log_new_contact(name, email, phone, message)
    create_call_log(create_contact(name, email, phone), message)
  end

  def create_contact(name, email, phone)
    begin
      contact_attributes = {'mail' => [email],
                            'name' => name,
                            'phone' => [phone]}

      resp = Podio::Profile.create_space_contact(@config[:contact_space],
                                                 contact_attributes)
    rescue Exception => e
      puts "PodioWrapper:  rescue caught in create_contact #{e.message}"
      puts e.backtrace 
    end
    resp['profile_id']
  end

  def create_call_log(profile_id, message="")
    begin
      log_attributes = {'fields' => {'contact-details' => profile_id,
                                     'notes' => message}
                       }

      Podio::Item.create(@config[:app_id], log_attributes )
    rescue Exception => e
      puts "PodioWrapper:  rescue caught in create_contact #{e.message}"
      puts e.backtrace 
    end
  end

end

class PodioWrapper
  class << self
    def log_new_contact(name, email, phone)
      create_call_log(create_contact(name, email, phone))
    end

    def create_contact(name, email, phone)
      contact_attributes = {'mail' => [email],
                            'name' => name,
                            'phone' => [phone]}

      resp = Podio::Profile.create_space_contact(ENV['PODIO_CONTACT_SPACE'],
                                                 contact_attributes)
      resp['profile_id']
    end

    def create_call_log(profile_id)
      log_attributes = {'fields' => {'contact-details' => profile_id,
                                     'notes' => "a test message"}
                       }

      Podio::Item.create(ENV['PODIO_CALL_LOG_APP_ID'], log_attributes )
    end
  end

end

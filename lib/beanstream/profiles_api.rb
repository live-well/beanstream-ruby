# frozen_string_literal: true

module Beanstream
  class ProfilesAPI < Transaction
    def initialize(merchant_id: nil, profiles_api_key: nil, sub_merchant_id: nil, **kwargs)
      if merchant_id.nil? && profiles_api_key.nil? && sub_merchant_id.nil? && kwargs.empty?
        # No arguments provided
        raise ArgumentError, "Missing required keyword arguments: merchant_id, profiles_api_key"
      elsif merchant_id.nil? && profiles_api_key.nil? && sub_merchant_id.nil? && kwargs.is_a?(Hash)
        # Single hash argument style (backward compatibility)
        @merchant_id = kwargs[:merchant_id]
        @profiles_api_key = kwargs[:profiles_api_key]
        @sub_merchant_id = kwargs[:sub_merchant_id]
      else
        # Keyword arguments style (Ruby 3)
        @merchant_id = merchant_id
        @profiles_api_key = profiles_api_key
        @sub_merchant_id = sub_merchant_id
      end

      # Validate required fields
      raise ArgumentError, "merchant_id is required" if @merchant_id.nil?
      raise ArgumentError, "profiles_api_key is required" if @profiles_api_key.nil?
    end

    def profile_url
      "#{Beanstream.api_base_url}/profiles"
    end

    def profile_cards_url
      "#{Beanstream.api_base_url}/profiles/cards"
    end

    def getCreateProfileWithCardTemplate
      request = getProfileTemplate
      request[:card] = {
        name:         '',
        number:       '',
        expiry_month: '',
        expiry_year:  '',
        cvd:          ''
      }

      request
    end

    def getCreateProfileWithTokenTemplate
      request = getProfileTemplate
      request[:token] = {
        name: '',
        code: ''
      }

      request
    end

    # a template for a Secure Payment Profile
    def getProfileTemplate
      {
        language: '',
        comments: '',
        billing:  {
          name:          '',
          address_line1: '',
          address_line2: '',
          city:          '',
          province:      '',
          country:       '',
          postal_code:   '',
          phone_number:  '',
          email_address: ''
        },
        shipping: {
          name:          '',
          address_line1: '',
          address_line2: '',
          city:          '',
          province:      '',
          country:       '',
          postal_code:   '',
          phone_number:  '',
          email_address: ''
        },
        custom:   {
          ref1: '',
          ref2: '',
          ref3: '',
          ref4: '',
          ref5: ''
        }
      }
    end

    def create_profile(profile)
      transaction_post('POST', profile_url, @merchant_id, @profiles_api_key, profile)
    end

    def delete_profile(profileId)
      delUrl = profile_url + '/' + profileId
      transaction_post('DELETE', delUrl, @merchant_id, @profiles_api_key, nil)
    end

    def get_profile(profileId)
      getUrl = profile_url + '/' + profileId
      transaction_post('GET', getUrl, @merchant_id, @profiles_api_key, nil)
    end

    def update_profile(profile)
      getUrl = profile_url + '/' + profile['customer_code']
      # remove card field for profile update. Card updates are done using update_profile_card()
      profile.tap { |h| h.delete('card') } unless profile['card'].nil?

      transaction_post('PUT', getUrl, @merchant_id, @profiles_api_key, profile)
    end

    def self.profile_successfully_created(response)
      response['code'] == 1 && response['message'] == 'Operation Successful'
    end

    def self.profile_successfully_deleted(response)
      response['code'] == 1 && response['message'] == 'Operation Successful'
    end

    def add_profile_card(profile, card)
      addCardUrl = profile_url + '/' + profile['customer_code'] + '/cards/'
      transaction_post('POST', addCardUrl, @merchant_id, @profiles_api_key, card)
    end

    def get_profile_card(profile)
      getCardUrl = profile_url + '/' + profile['customer_code'] + '/cards/'
      transaction_post('get', getCardUrl, @merchant_id, @profiles_api_key)
    end

    def update_profile_card(profile, card_index, card)
      updateUrl = profile_url + '/' + profile['customer_code'] + '/cards/' + card_index.to_s
      transaction_post('PUT', updateUrl, @merchant_id, @profiles_api_key, card)
    end

    def delete_profile_card(profile, card_index)
      deleteUrl = profile_url + '/' + profile['customer_code'] + '/cards/' + card_index.to_s
      transaction_post('DELETE', deleteUrl, @merchant_id, @profiles_api_key, nil)
    end
  end
end

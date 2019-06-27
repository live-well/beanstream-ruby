require 'beanstream'

RSpec.describe Beanstream::ProfilesAPI do
  ProfilesAPI = Beanstream::ProfilesAPI

  before :each do
    Beanstream.merchant_id = ENV['MERCHANT_ID']
    Beanstream.payments_api_key = ENV['PAYMENTS_API_KEY']
    Beanstream.profiles_api_key = ENV['PROFILES_API_KEY']
  end

  let(:api) { ProfilesAPI.new }

  def card_for(name)
    {
      name:         name,
      number:       '4030000010001234',
      expiry_month: '07',
      expiry_year:  '22',
      cvd:          '123'
    }
  end

  def billing_for(name)
    {
      name:          name,
      address_line1: '123 Fake St.',
      city:          'Victoria',
      province:      'BC',
      country:       'CA',
      postal_code:   'v1v2v2',
      phone_number:  '12505551234',
      email_address: 'fake@example.com'
    }
  end

  it 'builds the expected profiles url' do
    expect(api.profile_url).to eq('/v1/profiles')
  end

  it 'builds the expected profile cards url' do
    expect(api.profile_cards_url).to eq('/v1/profiles/cards')
  end

  context 'can create a profile' do
    let(:token) do
      Beanstream.PaymentsAPI.get_legato_token(
        number:       '4030000010001234',
        expiry_month: '07',
        expiry_year:  '22',
        cvd:          '123'
      )
    end

    it 'with a credit card' do
      template = api.getCreateProfileWithCardTemplate
      template[:card] = template[:card].merge(card_for('Bob Test'))
      template[:billing] = template[:billing].merge(billing_for('Bob Test'))

      result = api.create_profile(template)
      expect(ProfilesAPI.profile_successfully_created(result)).to be(true)
    end

    it 'with a legato token' do
      template = api.getCreateProfileWithTokenTemplate
      template[:token] = template[:token].merge(
        name: 'Bob Test',
        code: token
      )
      template[:billing] = template[:billing].merge(billing_for('Bob Test'))

      result = api.create_profile(template)
      expect(ProfilesAPI.profile_successfully_created(result)).to be(true)
    end
  end

  context 'with an existing profile' do
    let(:profile) do
      api.create_profile(
        card:    card_for('Jill Test'),
        billing: billing_for('Jill Test')
      )
    end

    it 'can delete a profile' do
      expect(ProfilesAPI.profile_successfully_created(profile)).to be(true)

      result = api.delete_profile(profile['customer_code'])
      expect(ProfilesAPI.profile_successfully_deleted(result)).to be(true)
    end

    it 'can retrieve a profile' do
      result = api.get_profile(profile['customer_code'])
      expect(result).to_not be_nil
      expect(result['billing']['name']).to eq('Jill Test')

      api.delete_profile(profile['customer_code']) # delete it to clean up
    end
  end

  let(:profile_info) do
    {
      'language' => 'en',
      'comments' => 'test profile',
      'custom' => {
        'ref1' => 'i wish',
        'ref2' => 'i was',
        'ref3' => 'an oscar',
        'ref4' => 'mayer',
        'ref5' => 'weiner'
      }
    }
  end

  it 'can update a profile' do
    profile = api.create_profile(
      card:    card_for('Hilary Test'),
      billing: billing_for('Hilary Test')
    )
    expect(ProfilesAPI.profile_successfully_created(profile)).to be(true)
    profile_id = profile['customer_code']

    profile1 = api.get_profile(profile_id)
    expect(profile1).to_not be_nil
    expect(profile1['billing']['name']).to eq('Hilary Test')

    profile1['billing']['name'] = 'gizmo test'
    profile1.merge!(profile_info)
    api.update_profile(profile1)

    profile2 = api.get_profile(profile_id)
    expect(profile2).to_not be_nil
    expect(profile2['billing']['name']).to eq('gizmo test')
    expect(profile2['language']).to eq('en')
    expect(profile2['custom']['ref1']).to eq('i wish')
    expect(profile2['custom']['ref2']).to eq('i was')
    expect(profile2['custom']['ref3']).to eq('an oscar')
    expect(profile2['custom']['ref4']).to eq('mayer')
    expect(profile2['custom']['ref5']).to eq('weiner')

    api.delete_profile(profile_id) # delete the profile to clean up
  end

  context 'when managing cards' do
    let(:profile) do
      api.create_profile(billing: billing_for('Hilary Test'))
    end

    let(:card1) do
      { card: card_for('Hilary Test') }
    end

    let(:card2) do
      {
        card: {
          name:         'John Doe',
          number:       '5100000010001004',
          expiry_month: '12',
          expiry_year:  '14',
          cvd:          '123'
        }
      }
    end

    it 'can add a card' do
      new_card = api.add_profile_card(profile, card1)

      profile2 = api.get_profile(profile['customer_code'])
      expect(profile2['card']).to be_truthy
      expect(new_card['message']).to eq('Operation Successful')
    end

    it 'can get a card' do
      api.add_profile_card(profile, card1)
      card = api.get_profile_card(profile)

      expect(card).to be_truthy
      expect(card['message']).to eq('Operation Successful')
    end

    it 'can update a card' do
      api.add_profile_card(profile, card2)
      update_card = api.update_profile_card(profile, 1, card1)

      expect(update_card['message']).to eq('Operation Successful')
    end

    it 'can delete a card' do
      api.add_profile_card(profile, card2)
      deleted_card = api.delete_profile_card(profile, 1)
      expect(deleted_card['message']).to eq('Operation Successful')
    end
  end

  context 'when making payments' do
    let(:profile) do
      api.create_profile(
        card:    card_for('Bob Test'),
        billing: billing_for('Bob Test')
      )
    end
    let(:profile_id) { profile['customer_code'] }
    let(:payments_api) { Beanstream.PaymentsAPI }

    it 'can use a profile for a complete payment' do
      payment = payments_api.getProfilePaymentRequestTemplate
      payment[:payment_profile][:customer_code] = profile_id
      payment[:amount] = 77.50

      result = payments_api.make_payment(payment)
      expect(Beanstream::PaymentsAPI.payment_approved(result)).to be(true)
    end

    it 'can use a profile for an incomplete payment' do
      payment = payments_api.getProfilePaymentRequestTemplate
      payment[:payment_profile][:complete] = false # false for pre-auth
      payment[:payment_profile][:customer_code] = profile_id
      payment[:amount] = 80

      pre_auth = payments_api.make_payment(payment)
      result = payments_api.complete_preauth(pre_auth['id'], 40.50)
      expect(Beanstream::PaymentsAPI.payment_approved(result)).to be(true)
    end
  end
end

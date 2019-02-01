require 'beanstream'

RSpec.describe Beanstream::PaymentsAPI do
  PaymentsAPI = Beanstream::PaymentsAPI

  before :each do
    Beanstream.merchant_id = '300200578'
    Beanstream.payments_api_key = '4BaD82D9197b4cc4b70a221911eE9f70'
  end

  let(:api) { PaymentsAPI.new }

  it 'builds the expected payment url' do
    expect(api.make_payment_url).to eq('/v1/payments/')
  end

  it 'builds the expected return url' do
    expect(api.payment_returns_url('1234')).to eq('/v1/payments/1234/returns')
  end

  it 'builds the expected void url' do
    expect(api.payment_void_url('1234')).to eq('/v1/payments/1234/void')
  end

  context 'with a valid credit card payment' do
    let(:card_info) do
      {
        name:         'Mr. Card Testerson',
        number:       '4030000010001234',
        expiry_month: '07',
        expiry_year:  '22',
        cvd:          '123',
        complete:     true
      }
    end

    let(:complete_payment) do
      api.make_payment(
        order_number:   PaymentsAPI.generateRandomOrderId('test'),
        amount:         100,
        payment_method: Beanstream::PaymentMethods::CARD,
        card:           card_info
      )
    end

    let(:incomplete_payment) do
      api.make_payment(
        order_number:   PaymentsAPI.generateRandomOrderId('test'),
        amount:         100,
        payment_method: Beanstream::PaymentMethods::CARD,
        card:           card_info.merge(complete: false)
      )
    end

    let(:complete_id) { complete_payment['id'] }
    let(:incomplete_id) { incomplete_payment['id'] }

    it 'returns a valid transaction id for a complete payment' do
      expect(complete_id).to_not be_nil
    end

    it 'returns a valid transaction id for an incomplete payment' do
      expect(incomplete_id).to_not be_nil
    end

    it 'approves a complete transaction' do
      expect(PaymentsAPI.payment_approved(complete_payment)).to be(true)
    end

    it 'approves an incomplete transaction' do
      expect(PaymentsAPI.payment_approved(incomplete_payment)).to be(true)
    end

    it 'handles pre-auth and completion' do
      result = api.complete_preauth(incomplete_id, 59.50)
      expect(PaymentsAPI.payment_approved(result)).to be(true)
    end

    it 'can get a transaction' do
      result = api.get_transaction(complete_id)
      expect(result['message']).to eq('Approved')
      expect(result['type']).to eq('P')
    end

    it 'can return a transaction' do
      return_result = api.return_payment(complete_id, 100)
      expect(return_result['type']).to eq('R')
      expect(return_result['message']).to eq('Approved')

      get_after_return = api.get_transaction(complete_id)
      expect(get_after_return['total_refunds']).to eq(100.0)

      expect {
        api.void_payment(complete_id, 100)
      }.to raise_error(Beanstream::BusinessRuleException)
    end

    it 'can void a transaction' do
      void_result = api.void_payment(complete_id, 100)
      expect(void_result['type']).to eq('VP')
      expect(void_result['message']).to eq('Approved')

      get_after_void = api.get_transaction(complete_id)
      expect(get_after_void['adjusted_by'][0]['type']).to eq('VP')

      expect {
        api.return_payment(complete_id, 100)
      }.to raise_error(Beanstream::BusinessRuleException)
    end
  end

  it 'handles a declined credit card payment' do
    payment_details = {
      order_number:   PaymentsAPI.generateRandomOrderId('test'),
      amount:         100,
      payment_method: Beanstream::PaymentMethods::CARD,
      card:           {
        name:         'Mr Card Testerson',
        number:       '4003050500040005', # declined card
        expiry_month: '07',
        expiry_year:  '22',
        cvd:          '123',
        complete:     true
      }
    }

    expect { api.make_payment(payment_details) }.to(raise_error { |error|
      expect(error).to be_a(Beanstream::BeanstreamException)
      expect(error.user_facing_message).to eq('DECLINE')
      expect(error.is_user_error).to be(true)
    })
  end

  context 'with a valid legato token' do
    let(:token) do
      api.get_legato_token(
        number:       '4030000010001234',
        expiry_month: '07',
        expiry_year:  '22',
        cvd:          '123'
      )
    end

    it 'gets a value' do
      expect(token).to_not be_nil
    end

    it 'successfully allows payment' do
      result = api.make_payment(
        order_number:   PaymentsAPI.generateRandomOrderId('test'),
        amount:         13.99,
        payment_method: Beanstream::PaymentMethods::TOKEN,
        token:          {
          name:     'Bobby Test',
          code:     token,
          complete: true
        }
      )

      expect(PaymentsAPI.payment_approved(result)).to be(true)
    end

    it 'handles legato token pre-auth and completion' do
      make_result = api.make_payment(
        order_number:   PaymentsAPI.generateRandomOrderId('test'),
        amount:         13.99,
        payment_method: Beanstream::PaymentMethods::TOKEN,
        token:          {
          name:     'Bobby Test',
          code:     token,
          complete: false
        }
      )
      expect(PaymentsAPI.payment_approved(make_result)).to be(true)
      transaction_id = make_result['id']

      auth_result = api.complete_preauth(transaction_id, 10.33)
      expect(PaymentsAPI.payment_approved(auth_result)).to be(true)
    end
  end

  it 'does not get a random transaction id' do
    expect {
      api.get_transaction('500')
    }.to raise_error(Beanstream::InvalidRequestException)
  end

  it 'does not return a random transaction id' do
    expect {
      api.return_payment('500', 100)
    }.to raise_error(Beanstream::InvalidRequestException)
  end

  it 'does not void a random transaction id' do
    expect {
      api.void_payment('500', 100)
    }.to raise_error(Beanstream::InvalidRequestException)
  end
end

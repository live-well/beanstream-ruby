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

  it 'successfully allows payment with a credit card' do
    result = api.make_payment(
      order_number:   PaymentsAPI.generateRandomOrderId('test'),
      amount:         100,
      payment_method: Beanstream::PaymentMethods::CARD,
      card:           {
        name:         'Mr. Card Testerson',
        number:       '4030000010001234',
        expiry_month: '07',
        expiry_year:  '22',
        cvd:          '123',
        complete:     true
      }
    )

    expect(PaymentsAPI.payment_approved(result)).to be(true)
  end

  it 'successfully allows payment with a legato token' do
    token = api.get_legato_token(
      number:       '4030000010001234',
      expiry_month: '07',
      expiry_year:  '22',
      cvd:          '123'
    )

    expect(token).to_not be_nil

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
end

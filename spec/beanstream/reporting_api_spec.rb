require 'beanstream'

RSpec.describe Beanstream::ReportingAPI do
  before :each do
    Beanstream.merchant_id = ENV['MERCHANT_ID']
    Beanstream.payments_api_key = ENV['PAYMENTS_API_KEY']
    Beanstream.reporting_api_key = ENV['REPORTING_API_KEY']
  end

  it 'makes the correct reports URL' do
    expect(Beanstream.ReportingAPI.reports_url).to eq('/v1/reports')
  end

  it 'successfully finds payments' do
    prefix = SecureRandom.hex(4)
    order_num1 = Beanstream::PaymentsAPI.generateRandomOrderId(prefix)
    order_num2 = Beanstream::PaymentsAPI.generateRandomOrderId(prefix)
    order_num3 = Beanstream::PaymentsAPI.generateRandomOrderId(prefix)

    make_payment(prefix, order_num1, 100.0)
    make_payment(prefix, order_num2, 33.29)
    make_payment(prefix, order_num3, 21.55)

    # Get all transactions within a time span
    results = search(1, 3)
    expect(results.length).to be(3)

    # Find transaction by order number
    results = search(
      1,
      10,
      Beanstream::Criteria.new(:order_number, Operators::EQUALS, order_num1)
    )
    expect(results.length).to be(1)
    expect(results[0]['trn_order_number']).to eq(order_num1)

    # Find Transactions 2 and 3 by ref1 and amount
    results = search(
      1,
      10,
      [
        Beanstream::Criteria.new(:ref1, Operators::EQUALS, prefix),
        Beanstream::Criteria.new(:amount, Operators::LESS_THAN, 50)
      ]
    )
    expect(results.length).to be(2)
  end

  def make_payment(prefix, order_number, amount)
    purchase = payment_info(prefix, order_number, amount)

    result = Beanstream.PaymentsAPI.make_payment(purchase)
    expect(Beanstream::PaymentsAPI.payment_approved(result)).to be(true)
  end

  def search(start_row, stop_row, criteria = nil)
    last_3_hours = Time.now.getlocal('-08:00') - 3 * 60 * 60
    next_3_hours = Time.now.getlocal('-08:00') + 3 * 60 * 60

    Beanstream.ReportingAPI.search_transactions(
      last_3_hours,
      next_3_hours,
      start_row,
      stop_row,
      criteria
    )
  end

  def payment_info(prefix, order_number, amount)
    {
      'order_number' => order_number,
      'amount' => amount,
      'payment_method' => Beanstream::PaymentMethods::CARD,
      'card' => test_card,
      'custom' => { 'ref1' => prefix }
    }
  end

  def test_card
    {
      'name' => 'Mr. Card Testerson',
      'number' => '4030000010001234',
      'expiry_month' => '07',
      'expiry_year' => '22',
      'cvd' => '123',
      'complete' => true
    }
  end
end

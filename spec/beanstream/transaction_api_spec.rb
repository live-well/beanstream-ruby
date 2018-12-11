require 'beanstream'

describe Beanstream::Transaction do
  let(:transaction) { Beanstream::Transaction.new }

  it 'encodes predictably' do
    expect(transaction.encode('12345', 'abcdefg')).to eq('MTIzNDU6YWJjZGVmZw==')
  end
end
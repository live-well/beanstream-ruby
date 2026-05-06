require 'beanstream'

RSpec.describe Beanstream::Transaction do
  let(:transaction) { Beanstream::Transaction.new }

  around do |example|
    original_ssl_ca_cert = Beanstream.ssl_ca_cert
    example.run
    Beanstream.ssl_ca_cert = original_ssl_ca_cert
  end

  it 'encodes predictably' do
    expect(transaction.encode('12345', 'abcdefg')).to eq('MTIzNDU6YWJjZGVmZw==')
  end

  it 'does not set ssl_ca_file when custom ca path is unset' do
    Beanstream.ssl_ca_cert = nil
    captured_args = nil

    allow(RestClient::Request).to receive(:execute) do |args|
      captured_args = args
      '{}'
    end

    transaction.transaction_post(:post, '/v1/payments/', '12345', 'abcdefg', amount: 1)

    expect(captured_args).not_to have_key(:ssl_ca_file)
  end

  it 'sets ssl_ca_file when custom ca path is configured' do
    Beanstream.ssl_ca_cert = '/tmp/custom-ca.pem'
    captured_args = nil

    allow(RestClient::Request).to receive(:execute) do |args|
      captured_args = args
      '{}'
    end

    transaction.transaction_post(:post, '/v1/payments/', '12345', 'abcdefg', amount: 1)

    expect(captured_args[:ssl_ca_file]).to eq('/tmp/custom-ca.pem')
  end
end

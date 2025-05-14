# frozen_string_literal: true

require 'securerandom'

module Beanstream
  class PaymentMethods
    CARD = 'card'
    CASH = 'cash'
    CHEQUE = 'cheque'
    TOKEN = 'token'
    PROFILE = 'payment_profile'
  end

  class PaymentsAPI < Transaction
    def initialize(merchant_id:, payments_api_key:, sub_merchant_id:)
      @merchant_id = merchant_id
      @payments_api_key = payments_api_key
      @sub_merchant_id = sub_merchant_id
    end

    def self.generateRandomOrderId(prefix)
      "#{prefix}_#{SecureRandom.hex(8)}"
    end

    # Urls

    def make_payment_url
      "#{Beanstream.api_base_url}/payments/"
    end

    def payment_returns_url(transaction_id)
      "#{Beanstream.api_base_url}/payments/#{transaction_id}/returns"
    end

    def payment_void_url(transaction_id)
      "#{Beanstream.api_base_url}/payments/#{transaction_id}/void"
    end

    def get_transaction_url(transaction_id)
      "#{Beanstream.api_base_url}/payments/#{transaction_id}"
    end

    # Payment Request Hash for making a payment with a Legato token
    def getTokenPaymentRequestTemplate
      request = getPaymentRequestTemplate
      request[:payment_method] = PaymentMethods::TOKEN
      request[:token] = {
        name:     '',
        code:     '',
        complete: true
      }

      request
    end

    # Payment Request Hash for making a payment with a credit card number
    def getCardPaymentRequestTemplate
      request = getPaymentRequestTemplate
      request[:payment_method] = PaymentMethods::CARD
      request[:card] = {
        name:         '',
        number:       '',
        expiry_month: '',
        expiry_year:  '',
        cvd:          '',
        complete:     true
      }

      request
    end

    # Payment Request Hash for making a payment with a Payment Profile
    def getProfilePaymentRequestTemplate
      request = getPaymentRequestTemplate
      request[:payment_method] = PaymentMethods::PROFILE
      request[:payment_profile] = {
        customer_code: '',
        card_id:       1,
        complete:      true
      }

      request
    end

    # Base Payment Request Hash for making a payments
    # Use one of getTokenPaymentRequestTemplate, getCardPaymentRequestTemplate, or getProfilePaymentRequestTemplate
    # +Required parameters+:: :amount, :order_number, :payment_method, and one of [:card, :token, :payment_profile] if not paying for Cash or Cheque.
    # Use PaymentMethods:: for the available payment_method options
    def getPaymentRequestTemplate
      {
        order_number: '',
        amount:       0,
        language:     '',
        customer_ip:  '',
        term_url:     '',
        comments:     '',
        billing:      {
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
        shipping:     {
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
        custom:       {
          ref1: '',
          ref2: '',
          ref3: '',
          ref4: '',
          ref5: ''
        }
      }
    end

    # API operations

    # Make a payment. If the payment is approved the PaymentResponse will be returned. If for any reason
    # the payment is declined or if there is a connection error an exception will be thrown.
    # This will accept a PaymentRequest Hash as defined by getTokenPaymentRequestTemplate(), getCardPaymentRequestTemplate(),
    # or getProfilePaymentRequestTemplate().
    # +PreAuth+:: For a pre-auth you must set the 'complete' parameter of the Card, Token, or Profile to be 'false'.
    def make_payment(payment)
      transaction_post('POST', make_payment_url, @merchant_id, @payments_api_key, payment)
    end

    def complete_preauth(transaciton_id, amount)
      complete_url = make_payment_url + transaciton_id + '/completions'
      completion = { amount: amount }
      transaction_post('POST', complete_url, @merchant_id, @payments_api_key, completion)
    end

    def self.payment_approved(payment_response)
      payment_response['approved'] == '1' && payment_response['message'] == 'Approved'
    end

    def get_legato_token(card_info)
      turl = '/scripts/tokenization/tokens'
      result = Transaction.new.transaction_post('POST', turl, '', '', card_info)
      result['token']
    end

    def get_transaction(transaction_id)
      transaction_post('GET', get_transaction_url(transaction_id), @merchant_id, @payments_api_key)
    end

    def return_payment(transaction_id, amount)
      data = { amount: amount }
      transaction_post('POST', payment_returns_url(transaction_id), @merchant_id, @payments_api_key, data)
    end

    def void_payment(transaction_id, amount)
      data = { amount: amount }
      transaction_post('POST', payment_void_url(transaction_id), @merchant_id, @payments_api_key, data)
    end
  end
end

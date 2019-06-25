module Beanstream
  class ReportingAPI < Transaction
    def initialize(sub_merchant_id = nil)
      @sub_merchant_id = sub_merchant_id
    end

    def reports_url
      "#{Beanstream.api_base_url}/reports"
    end

    def search_transactions(start_date, end_date, start_row, end_row, criteria = nil)
      unless start_date.is_a?(Time)
        raise InvalidRequestException.new(0, 0, 'start_date must be of type Time in ReportingApi.search_transactions', 0)
      end
      unless end_date.is_a?(Time)
        raise InvalidRequestException.new(0, 0, 'end_date must be of type Time in ReportingApi.search_transactions', 0)
      end

      if !criteria.nil? && !criteria.kind_of?(Array) && !criteria.is_a?(Beanstream::Criteria)
        puts "criteria was of type: #{criteria.class}"
        raise InvalidRequestException.new(0, 0, 'criteria must be of type Array<Critiera> or Criteria in ReportingApi.search_transactions', 0)
      end
      if criteria.is_a?(Beanstream::Criteria)
        # make it an array
        criteria = Array[criteria]
      end

      start_date = start_date.strftime '%Y-%m-%dT%H:%M:%S'
      end_date = end_date.strftime '%Y-%m-%dT%H:%M:%S'

      criteria_hash = Array[]
      if !criteria.nil? && !criteria.empty?
        criteria.each do |c|
          criteria_hash << c.to_hash
        end
      end
      query = {
        'name' => 'Search',
        'start_date' => start_date,
        'end_date' => end_date,
        'start_row' => start_row,
        'end_row' => end_row,
        'criteria' => criteria_hash
      }
      # puts "\n\nReport search query #{query}\n\n"
      val = transaction_post('POST', reports_url, Beanstream.merchant_id, Beanstream.reporting_api_key, query)
      val['records']
    end
  end

  class Criteria
    attr_accessor :field, :operator, :value

    FIELDS = {
      transaction_id:     1,
      amount:             2,
      masked_card_number: 3,
      card_owner:         4,
      order_number:       5,
      ip_ddress:          6,
      authorization_code: 7,
      trans_type:         8,
      card_type:          9,
      response:           10,
      billing_name:       11,
      billing_email:      12,
      billing_phone:      13,
      processed_by:       14,
      ref1:               15,
      ref2:               16,
      ref3:               17,
      ref4:               18,
      ref5:               19,
      product_name:       20,
      product_id:         21,
      cust_code:          22,
      id_adjustment_to:   23,
      id_adjusted_by:     24
    }.freeze

    def initialize(field, operator, value)
      @field = field.is_a?(Symbol) ? FIELDS.fetch(field) : field
      @operator = operator
      @value = value
    end

    def to_hash
      { 'field' => @field, 'operator' => @operator, 'value' => @value }
    end
  end
end

module Operators
  EQUALS = '%3D'.freeze
  LESS_THAN = '%3C'.freeze
  GREATER_THAN = '%3E'.freeze
  LESS_THAN_EQUAL = '%3C%3D'.freeze
  GREATER_THAN_EQUAL = '%3E%3D'.freeze
  STARTS_WITH = 'START%20WITH'.freeze
end

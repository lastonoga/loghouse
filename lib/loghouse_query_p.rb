class LoghouseQueryP < Parslet::Parser
  include ParsletExtensions

  QUERY_OPERATORS             = %w[and or]
  EXPRESSION_ALL_OPERATORS    = %w[!= =]
  EXPRESSION_NUMBER_OPERATORS = %w[>= <= > < ]
  EXPRESSION_STRING_OPERATORS = %w[=~]
  ANY_RESERVED_KEY            = "*"
  LABEL_RESERVED_KEY          = "~"

  rule(:query_operator) do
    q_op = nil
    QUERY_OPERATORS.each do |op|
      if q_op.nil?
        q_op = stri(op)
      else
        q_op |= stri(op)
      end
    end

    spaced(q_op.as(:q_op))
  end

  rule(:expression_string_operator) do
    e_op = nil
    (EXPRESSION_STRING_OPERATORS + EXPRESSION_ALL_OPERATORS).each do |op|
      if e_op.nil?
        e_op = str(op)
      else
        e_op |= str(op)
      end
    end

    spaced(e_op.as(:e_op))
  end

  rule(:expression_number_operator) do
    e_op = nil
    (EXPRESSION_NUMBER_OPERATORS + EXPRESSION_ALL_OPERATORS).each do |op|
      if e_op.nil?
        e_op = str(op)
      else
        e_op |= str(op)
      end
    end

    spaced(e_op.as(:e_op))
  end

  rule(:expression_operator) do
    expression_string_operator |
    expression_number_operator
  end

  rule(:expression_null) do
    spaced(stri('is null').as(:is_null)) |
    spaced(stri('is not null').as(:not_null))
  end

  rule(:expression_boolean) do
    spaced(stri('is true').as(:is_true)) |
    spaced(stri('is false').as(:is_false))
  end

  rule(:value) {
    match['0-9\.'].repeat(1).as(:num_value) |
    match['^\s\'\"'].repeat(1).as(:str_value) |
    str('"') >> match['^\"'].repeat.as(:str_value) >> str('"') |
    str("'") >> match['^\''].repeat.as(:str_value) >> str("'")
  }

  rule(:any_key) {
    stri(ANY_RESERVED_KEY).as(:any_key)
  }

  rule(:label_key) {
    stri(LABEL_RESERVED_KEY) >> (match['a-zA-Z'] >> match['a-zA-Z0-9_\-\.'].repeat(0)).as(:label_key)
  }

  rule(:key) {
    (match['a-zA-Z@'] >> match['a-zA-Z0-9_\-\.'].repeat(0)).as(:custom_key)
  }

  rule(:expression) do
    (
      (key >> expression_null) |
      (key >> expression_boolean) |
      ((key | any_key) >> expression_operator >> value) |
      (label_key >> expression_string_operator >> value)
    ).as(:expression)
  end

  rule(:query) { (expression >> subquery.maybe.as(:subquery)).as(:query) }
  rule(:subquery) { query_operator >> query }

  root :query
end

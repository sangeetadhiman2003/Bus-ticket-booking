class UnauthorizedHoldError < StandardError
  def initialize(message = "You are not authorized to access this hold.")
    super(message)
  end
end

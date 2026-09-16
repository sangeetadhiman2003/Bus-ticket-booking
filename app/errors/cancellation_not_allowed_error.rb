class CancellationNotAllowedError < StandardError
  def initialize(message = "This booking cannot be cancelled.")
    super(message)
  end
end

class FutureTransfer
  attr_accessor :message, :files

  def initialize(message:, files: [])
    @message = message
    @files = files
  end

  def to_request_params
    {
      message: message,
      files: files.map(&:to_request_params),
    }
  end
end

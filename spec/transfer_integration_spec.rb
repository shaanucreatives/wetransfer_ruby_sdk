# frozen_string_literal: true

require 'spec_helper'

describe WeTransfer::Client do
  let(:test_logger) do
    Logger.new($stderr).tap { |log| log.level = Logger::WARN }
  end

  let(:client) do
    WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
  end

  let(:file_locations) do
    %w[spec/files/Japan-01.jpg spec/files/Japan-02.jpg]
  end

  describe described_class::Transfers do
    it 'creates a transfer with multiple files' do
      transfer = client.create_transfer(message: 'Japan: 🏯 & 🎎') do |builder|
        file_locations.each do |file_location|
          builder.add_file(name: File.basename(file_location), io: File.open(file_location, 'rb'))
        end
      end
      expect(transfer).to be_kind_of(RemoteTransfer)

      # it has an url that is not available (yet)
      expect(transfer.url).to be(nil)
      # it has no files (yet)
      expect(transfer.files.first.url).to be(nil)
      # it is in an uploading state
      expect(transfer.state).to eq('uploading')

      # TODO: the file_locations and transfer.files are too coupled
      file_locations.each_with_index do |location, index|
        client.upload_file(
          object: transfer,
          file: transfer.files[index],
          io: File.open(location, 'rb')
        )
        client.complete_file!(
          object: transfer,
          file: transfer.files[index]
        )
      end

      result = client.complete_transfer(transfer: transfer)

      # it has an url that is available
      expect(result.url =~ %r|^https://we.tl/t-|).to be_truthy

      # it is in a processing state
      expect(result.state).to eq('processing')

      response = Faraday.get(result.url)
      # it hits the short-url with redirect
      expect(response.status).to eq(302)
      expect(response['location']).to start_with('https://wetransfer.com/')
    end
  end
end

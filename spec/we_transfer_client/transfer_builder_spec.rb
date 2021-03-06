require 'spec_helper'

describe TransferBuilder do
  let(:transfer) { described_class.new }

  describe '#initialze' do
    it 'initializes with an empty files array' do
      expect(transfer.files.empty?).to be(true)
    end
  end

  describe '#add_file' do
    it 'returns an error when name is missing' do
      expect {
        transfer.add_file(io: File.open(__FILE__, 'rb'))
      }.to raise_error ArgumentError, /name/
    end

    it 'returns an error when io is missing' do
      expect {
        transfer.add_file(name: 'file name')
      }.to raise_error ArgumentError, /io/
    end

    it 'returns a error when file doesnt exists' do
      expect {
        transfer.add_file(name: 'file name', io: File.open('foo', 'rb'))
      }.to raise_error Errno::ENOENT
    end

    it 'adds a file when name and io is given' do
      transfer.add_file(name: 'file name', io: File.open(__FILE__, 'rb'))
      expect(transfer.files.first).to be_kind_of(FutureFile)
    end
  end

  describe '#add_file_at' do
    it 'adds a file from a path' do
      transfer.add_file_at(path: __FILE__)
      expect(transfer.files.first).to be_kind_of(FutureFile)
    end

    it 'throws a Error when file doesnt exists' do
      expect {
        transfer.add_file_at(path: '/this/path/leads/to/nothing.exe')
      }.to raise_error Errno::ENOENT
    end

    pending 'should call #add_file' do
      skip "Lets not trigger status:400 errors"
      client = WeTransfer::Client.new(api_key: ENV.fetch('WT_API_KEY'), logger: test_logger)
      client.create_transfer(message: 'A transfer message') do |builder|
        expect(builder).to receive(:add_file).with(name: kind_of(String), io: kind_of(::File))
        builder.add_file_at(path: __FILE__)
      end
    end
  end
end

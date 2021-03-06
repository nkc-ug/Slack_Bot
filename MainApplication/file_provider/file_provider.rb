# frozen_string_literal:true

require 'open-uri'
require 'json'
require 'http'
require 'slack'

class FileProvider
  # download file to `download_images/` directory
  # @param endpoint <string> image file link
  # @return <string> if succeed, return absolute image file path
  def download_file(endpoint)

    Dir.mkdir('download_images') unless Dir.exist?('download_images')
    # 1. 'https://pbs.twimg.com/media/BspTawrCEAAwQnP.jpg:large' => 'BspTawrCEAAwQnP.jpg|:large'
    # 2. 'BspTawrCEAAwQnP.jpg:large' => 'BspTawrCEAAwQnP.jpg'
    filename = File.basename(endpoint)[/.*.(jpg|png|gif)/]
    absolute_path = ''
    URI.open(endpoint) do |binary|
      File.open("#{__dir__}/../download_images/#{filename}", mode = 'w'){|file|
        file.write(binary.read)
      }
      absolute_path = File.expand_path("#{__dir__}/../download_images/#{filename}")
    end
    absolute_path
  rescue OpenURI::HTTPError
    'リソース取得に失敗しました'
  end

  # upload file to slack API
  # https://api.slack.com/methods/files.upload
  # @param filepath
  # @param channel <string> sending channel('general', 'HOGE0A00Z'...)
  # @return <boolean> upload result
  def upload_file(filepath, channel)
    slack_api_key = ENV['SLACK_API_KEY']
    Slack.configure do |config|
      config.token = slack_api_key
    end

    ## upload file
    result = Slack.files_upload(
      file: Faraday::UploadIO.new(filepath, 'image/jpg'),
      filename: File.basename(filepath),
      filetype: File.extname(filepath),
      channels: channel
    )

    result['ok']
  end
end
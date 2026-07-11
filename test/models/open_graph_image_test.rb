require "test_helper"

class OpenGraphImageTest < ActiveSupport::TestCase
  test "generate attaches the screenshot" do
    open_graph_image = OpenGraphImage.instance
    browser = mock_browser(screenshot_data: Base64.strict_encode64("png data"))

    open_graph_image.stub(:render_html, "<html></html>") do
      open_graph_image.stub(:sleep, nil) do
        open_graph_image.generate!(browser: browser)
      end
    end

    assert open_graph_image.image.attached?
    assert_equal "home-og.png", open_graph_image.image.filename.to_s
    assert_equal "image/png", open_graph_image.image.content_type
    assert_equal "png data", open_graph_image.image.download
    assert_mock browser
  end

  test "generate keeps the existing image when screenshot generation fails" do
    open_graph_image = OpenGraphImage.instance
    open_graph_image.image.attach(
      io: StringIO.new("existing image"),
      filename: "existing.png",
      content_type: "image/png"
    )
    browser = mock_browser(screenshot_data: nil)

    result = nil
    open_graph_image.stub(:render_html, "<html></html>") do
      open_graph_image.stub(:sleep, nil) do
        result = open_graph_image.generate!(browser: browser)
      end
    end

    assert_nil result
    assert_equal "existing image", open_graph_image.image.download
    assert_mock browser
  end

  private

  def mock_browser(screenshot_data:)
    browser = Minitest::Mock.new
    browser.expect(:go_to, nil, [String])
    browser.expect(:screenshot, screenshot_data, [], format: :png, full: true)
    browser.expect(:quit, nil)
    browser
  end
end

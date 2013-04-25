require 'test_helper'

class CrawlerControllerTest < ActionController::TestCase
  test "should get dir" do
    get :dir
    assert_response :success
  end

  test "should get speed" do
    get :speed
    assert_response :success
  end

  test "should get stop" do
    get :stop
    assert_response :success
  end

  test "should get turn" do
    get :turn
    assert_response :success
  end

end

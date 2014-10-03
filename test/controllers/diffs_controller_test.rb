require 'test_helper'

class DiffsControllerTest < ActionController::TestCase
  setup do
    @diff = diffs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:diffs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create diff" do
    assert_difference('Diff.count') do
      post :create, diff: { config_file_id: @diff.config_file_id, description: @diff.description, left_id: @diff.left_id, right_id: @diff.right_id, title: @diff.title }
    end

    assert_redirected_to diff_path(assigns(:diff))
  end

  test "should show diff" do
    get :show, id: @diff
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @diff
    assert_response :success
  end

  test "should update diff" do
    patch :update, id: @diff, diff: { config_file_id: @diff.config_file_id, description: @diff.description, left_id: @diff.left_id, right_id: @diff.right_id, title: @diff.title }
    assert_redirected_to diff_path(assigns(:diff))
  end

  test "should destroy diff" do
    assert_difference('Diff.count', -1) do
      delete :destroy, id: @diff
    end

    assert_redirected_to diffs_path
  end
end

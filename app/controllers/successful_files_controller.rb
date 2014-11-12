class SuccessfulFilesController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :require_login, :only => :create
  before_action :set_successful_file, only: [:destroy]
  after_action :add_action, only: [:create, :destroy]

  # POST /unmatched_files
  # POST /diffs.json
  def create
    @successful_file = SuccessfulFile.new(successful_file_params)

    respond_to do |format|
      if @successful_file.save
        format.json { head :no_content }
      else
        format.json { render json: @successful_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diffs/1
  # DELETE /diffs/1.json
  def destroy
    @successful_file.destroy
    respond_to do |format|
      format.html { redirect_to request.referer, notice: 'Successful File was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private

    # Use callbacks to share common setup or constraints between actions.
    def set_successful_file
      @successful_file = SuccessfulFile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def successful_file_params
      params.require(:successful_file).permit(:result_id, :left_name, :right_name)
    end

    def add_action
      if request.format.symbol == :html
        Action.create(:action => action_name, :item => 'successful_file', :user_id => @current_user.id, :item_id => @successful_file.id)
      end
    end

end

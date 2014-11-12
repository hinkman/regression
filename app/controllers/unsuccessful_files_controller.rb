class UnsuccessfulFilesController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :require_login, :only => :create
  before_action :set_unsuccessful_file, only: [:destroy]
  after_action :add_action, only: [:create, :destroy]

  # POST /unmatched_files
  # POST /diffs.json
  def create
    @unsuccessful_file = UnsuccessfulFile.new(unsuccessful_file_params)

    respond_to do |format|
      if @unsuccessful_file.save
        format.json { head :no_content }
      else
        format.json { render json: @unsuccessful_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diffs/1
  # DELETE /diffs/1.json
  def destroy
    @unsuccessful_file.destroy
    respond_to do |format|
      format.html { redirect_to request.referer, notice: 'Unsuccessful File was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private

    # Use callbacks to share common setup or constraints between actions.
    def set_unsuccessful_file
      @unsuccessful_file = UnsuccessfulFile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unsuccessful_file_params
      params.require(:unsuccessful_file).permit(:result_id, :left_line_number, :right_line_number, :left_line, :right_line, :compare_key)
    end

    def add_action
      if request.format.symbol == :html
        Action.create(:action => action_name, :item => 'unsuccessful_file', :user_id => @current_user.id, :item_id => @unsuccessful_file.id)
      end
    end

end

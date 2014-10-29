class UnmatchedFilesController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :require_login, :only => :create
  before_action :set_unmatched_file, only: [:destroy]
  after_action :add_action, only: [:create, :destroy]

  # POST /unmatched_files
  # POST /diffs.json
  def create
    @unmatched_file = UnmatchedFile.new(unmatched_file_params)

    respond_to do |format|
      if @unmatched_file.save
        format.json { head :no_content }
      else
        format.json { render json: @unmatched_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diffs/1
  # DELETE /diffs/1.json
  def destroy
    @unmatched_file.destroy
    respond_to do |format|
      format.html { redirect_to request.referer, notice: 'Unmatched File was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private

    # Use callbacks to share common setup or constraints between actions.
    def set_unmatched_file
      @unmatched_file = UnmatchedFile.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unmatched_file_params
      params.require(:unmatched_file).permit(:result_id, :side, :name, :url)
    end

    def add_action
      if request.format.symbol == :html
        Action.create(:action => action_name, :item => 'unmatched_file', :user_id => @current_user.id, :item_id => @unmatched_file.id)
      end
    end

end

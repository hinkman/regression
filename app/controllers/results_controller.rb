class ResultsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :update
  skip_before_filter :require_login, :only => :update
  before_action :set_result, only: [:update, :destroy]
  after_action :add_action, only: [:update, :destroy]

  # PATCH/PUT /result/1
  # PATCH/PUT /result/1.json
  def update
    respond_to do |format|
      if @result.update(result_params)
        format.html { redirect_to((session.delete(:return_to) || @result), notice: 'Result was successfully updated.') }
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json { render json: @result.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diffs/1
  # DELETE /diffs/1.json
  def destroy
    @result.destroy
    respond_to do |format|
      format.html { redirect_to request.referer, notice: 'Result was successfully destroyed.' }
      format.json { head :no_content }
    end
  end


  private

    # Use callbacks to share common setup or constraints between actions.
    def set_result
      @result = Result.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def result_params
      params.require(:result).permit(:pct_complete, :path, :left_count, :right_count)
    end

    def add_action
      if request.format.symbol == :html
        Action.create(:action => action_name, :item => 'result', :user_id => @current_user.id, :item_id => @result.id)
      end
    end

end

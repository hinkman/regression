class FileSetsController < ApplicationController
  before_action :set_file_set, only: [:show, :edit, :update, :destroy]
  after_action :add_action, only: [:create, :edit, :update, :destroy]

  # GET /file_sets
  # GET /file_sets.json
  def index
    @q = FileSet.search(params[:q])
    @file_sets = @q.result.includes(:diffs_left, :diffs_right)
  end

  # GET /file_sets/1
  # GET /file_sets/1.json
  def show
  end

  # GET /file_sets/new
  def new
    @file_set = FileSet.new
  end

  # GET /file_sets/1/edit
  def edit
    session[:return_to] = request.referer
  end

  # POST /file_sets
  # POST /file_sets.json
  def create
    @file_set = FileSet.new(file_set_params)
    @file_set.is_active = true

    respond_to do |format|
      if @file_set.save
        format.html { redirect_to((session.delete(:return_to) || @file_set), notice: 'File set was successfully created.') }
        format.json { render :show, status: :created, location: @file_set }
      else
        format.html { render :new }
        format.json { render json: @file_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /file_sets/1
  # PATCH/PUT /file_sets/1.json
  def update
    respond_to do |format|
      if @file_set.update(file_set_params)
        format.html { redirect_to((session.delete(:return_to) || @file_set), notice: 'File set successfully updated.') }
        format.json { render :show, status: :ok, location: @file_set }
      else
        format.html { render :edit }
        format.json { render json: @file_set.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /file_sets/1
  # DELETE /file_sets/1.json
  def destroy
    # @file_set.destroy
    @file_set.update(is_active: false)

    respond_to do |format|
      format.html { redirect_to file_sets_url, notice: 'File set was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_file_set
      @file_set = FileSet.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def file_set_params
      params.require(:file_set).permit(:name, :description, :fs)
    end

    def add_action
      Action.create(:action => action_name, :item => 'file_set', :user_id => @current_user.id, :item_id => @file_set.id)
    end
end

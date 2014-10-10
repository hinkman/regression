class DiffsController < ApplicationController

  before_action :set_diff, only: [:run, :show, :edit, :update, :destroy]
  before_action :set_config_files, only: [:show, :edit, :update, :destroy]
  before_action :set_file_sets, only: [:show, :edit, :update, :destroy]
  after_action :add_action, only: [:run, :create, :edit, :update, :destroy]

  # GET /diffs
  # GET /diffs.json
  def index
    @q = Diff.search(params[:q])
    @diffs = @q.result.includes(:left_file_set, :right_file_set, :results, :config_file)
  end

  # GET /diffs/1
  # GET /diffs/1.json
  def show
  end

  # GET /diffs/new
  def new
    @diff = Diff.new
  end

  # GET /diffs/1/edit
  def edit
  end

  def run
    @result=Result.new(:diff_id => @diff.id, :is_active => true, :pct_complete => 0)
    @result.save
    respond_to do |format|
      # format.html { redirect_to show_diff_path, status: :ok, location: @diff, notice: 'run was called.' }
      format.html { redirect_to @diff, notice: @result.id }
      format.json { head :no_content }
    end
  end

  # POST /diffs
  # POST /diffs.json
  def create
    @diff = Diff.new(diff_params)
    @diff.is_active = true

    respond_to do |format|
      if @diff.save
        format.html { redirect_to @diff, notice: 'Diff was successfully created.' }
        format.json { render :show, status: :created, location: @diff }
      else
        format.html { render :new }
        format.json { render json: @diff.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /diffs/1
  # PATCH/PUT /diffs/1.json
  def update
    respond_to do |format|
      if @diff.update(diff_params)
        format.html { redirect_to @diff, notice: 'Diff was successfully updated.' }
        format.json { render :show, status: :ok, location: @diff }
      else
        format.html { render :edit }
        format.json { render json: @diff.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /diffs/1
  # DELETE /diffs/1.json
  def destroy
    @diff.update(is_active: false)
    respond_to do |format|
      format.html { redirect_to diffs_url, notice: 'Diff was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_diff
      @diff = Diff.find(params[:id])
    end

    def set_config_files
      @config_files = ConfigFile.all
    end

    def set_file_sets
      @file_sets = FileSet.all
    end

  # Never trust parameters from the scary internet, only allow the white list through.
    def diff_params
      params.require(:diff).permit(:title, :description, :config_file_id, :left_id, :right_id)
    end

    def add_action
      Action.create(:action => action_name, :item => 'diff', :user_id => @current_user.id, :item_id => @diff.id)
    end

end

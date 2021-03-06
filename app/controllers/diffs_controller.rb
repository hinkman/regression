class DiffsController < ApplicationController

  before_action :set_diff, only: [:run, :show, :edit, :update, :destroy]
  before_action :set_config_files, only: [:show, :edit, :update, :destroy]
  before_action :set_file_sets, only: [:show, :edit, :update, :destroy]
  after_action :add_action, only: [:run, :create, :edit, :update, :destroy]

  # GET /diffs
  # GET /diffs.json
  # TODO clean up diff/results query
  def index
    if params[:q].to_s.include? 'results_updated_at desc'
      @q = Diff.joins('LEFT OUTER JOIN `results` ON `results`.`diff_id` = `diffs`.`id` AND (results.id in (select a.id from (select id,diff_id from results order by id desc)  a group by a.diff_id))').order("results.updated_at desc").search()
    elsif params[:q].to_s.include? 'results_updated_at asc'
      @q = Diff.joins('LEFT OUTER JOIN `results` ON `results`.`diff_id` = `diffs`.`id` AND (results.id in (select a.id from (select id,diff_id from results order by id desc)  a group by a.diff_id))').order("results.updated_at asc").search()
    else
      @q = Diff.joins('LEFT OUTER JOIN `results` ON `results`.`diff_id` = `diffs`.`id` AND (results.id in (select a.id from (select id,diff_id from results order by id desc)  a group by a.diff_id))').search(params[:q])
    end
    @diffs = @q.result.includes(:config_file, :left_file_set, :right_file_set, :results)
    @q = Diff.search(params[:q])
  end

  # GET /diffs/1
  # GET /diffs/1.json
  def show
    @q = Result.where_diff_id(@diff.id).search(params[:q])
    @working_results = @q.result
    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def from_result_id
    @result = Result.find(params[:result_id])
    @unmatched_left = UnmatchedFile.where_result_id_and_side(@result.id,'left').order('name ASC')
    @unmatched_right = UnmatchedFile.where_result_id_and_side(@result.id,'right').order('name ASC')
    @successful = SuccessfulFile.where_result_id(@result.id).order('left_name ASC')
    @unsuccessful = UnsuccessfulFile.where_result_id(@result.id).order('compare_key,id ASC')
    @unsuccessful_count = UnsuccessfulFile.where_result_id(@result.id).group('compare_key')
    respond_to do |format|
      format.js {}
    end
  end

  # GET /diffs/new
  def new
    @diff = Diff.new
  end

  # GET /diffs/1/edit
  def edit
    session[:return_to] = request.referer
  end

  def run
    @working_result=Result.new(:diff_id => @diff.id, :is_active => true, :pct_complete => 0)
    @working_result.save
    `(./bin/regression_diff.pl --result_id #{@working_result.id} --config_file #{@diff.config_file.cf.path} --left_zip #{@diff.left_file_set.fs.path} --right_zip #{@diff.right_file_set.fs.path} --output_prefix #{@current_user.login} 2>&1 | logger -t regression) > /dev/null 2>&1 &`
    # `(./bin/regression_diff.pl --result_id #{@working_result.id} --config_file #{@diff.config_file.cf.path} --left_zip #{@diff.left_file_set.fs.path} --right_zip #{@diff.right_file_set.fs.path} --output_prefix #{@current_user.login} > /tmp/regression.log 2>&1) > /dev/null 2>&1 &`
    sleep 2
    respond_to do |format|
      # format.html { redirect_to show_diff_path, status: :ok, location: @diff, notice: 'run was called.' }
      format.html { redirect_to @diff, notice: @working_result.id }
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
        format.html { redirect_to((session.delete(:return_to) || @diff), notice: 'Diff was successfully created.') }
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
        format.html { redirect_to((session.delete(:return_to) || @diff), notice: 'Diff was successfully updated.') }
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
    @diff.destroy
    # @diff.update(is_active: false)
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

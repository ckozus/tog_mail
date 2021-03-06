class Member::MessagesController < Member::BaseController

  include ActionView::Helpers::SanitizeHelper

  def show
    @message = current_user.get_message(params[:id])
    @message.read!
    respond_to do |format|
      format.html
      format.xml  { render :xml => @message }
    end
  end

  def index
    @folder   = (current_user.folders.find(params[:id]) unless params[:id].nil?) || current_user.inbox
    @messages = @folder.messages.paginate :page => params[:page]

    respond_to do |format|
      format.html
      format.rss  { render :rss => @messages }
    end
  end

  def new
    @from = current_user
    @to = User.active.find(params[:user_id]) if params[:user_id]
    respond_to do |format|
      format.html
      format.xml  { render :xml => @message }
    end
  end

  def create
    to_user = User.active.find(params[:message][:to_user_id])
    @message = Message.new(
    :from     => current_user,
    :to       => to_user,
    :subject  => sanitize(params[:message][:subject]),
    :content  => sanitize(params[:message][:content])
    )
    respond_to do |format|
      if @message.dispatch!
        flash[:ok] = 'Message was successfully delivered.'
        format.html { redirect_back_or_default(member_messages_path) }
        format.xml  { render :xml => @message, :status => :created, :location => member_message_path(:id => @message) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @message.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    message = Message.find(params[:id])
    folder_id = message.folder_id
    message.destroy
    redirect_to :action => 'index', :id => folder_id
  end

  def search
    @match ="%"+sanitize(params[:keyword])+"%"
    @msgs = Message.find_by_sql(["SELECT messages.id
      FROM messages  INNER JOIN
      messages ON messages.message_id = messages.id  INNER JOIN
      folders ON messages.folder_id = folders.id  INNER JOIN
      users ON folders.user_id = users.id
    WHERE  (user_id = ?) AND ((subject LIKE ?) OR (content LIKE ?))",current_user.id, @match,@match])
    @fol_msgs = Message.find(:all, :conditions => ['id in (?)',@msgs])
    render :update do |page|
      page.replace_html 'search', :partial => 'search', :object => @fol_msgs
    end
  end

  def reply
    @reply_to = current_user.received_messages.find params[:id]
    respond_to do |format|
      format.html
      format.xml  { render :xml => @message }
    end
  end

end
require_relative '../lib/soba/mieruka'

CONFIG = {
  :api_key => 'test_api_key',
  :private_key => 'open_sesami',
  #:version => '1.4'
}

ACCOUNT = {
  :user_name => 'shimokawa1@soba',
  :password => 'shimokawa1'
}

def gen_str(len)
  a = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  Array.new(len){a[rand(a.size)]}.join
end

describe Soba::Mieruka do
  before do
    @m = Soba::Mieruka.new(CONFIG)
  end
  
  def valid_account
    ACCOUNT
  end
  
  it 'can log in with valid attributes.' do
    expect {
      @m.login(valid_account)
      @m.logout
    }.should_not raise_error
  end
  
  context 'is logged in' do
    before do
      expect {
        @m.login(valid_account)
      }.should_not raise_error
    end
    
    it 'make a new session' do
      expect {
        session = @m.create_session(:session_name => 'test', :session_description => 'this is a test')
        session.should respond_to(:url)
        session.should respond_to(:soba_session_id)
      }.should_not raise_error
    end
    
    it 'get the session list' do
      expect {
        sessions = @m.sessions
        sessions.should be_a(Array)
        sessions.each do |session|
          session.should be_a(Soba::Mieruka::Session)
          session.should respond_to(:id)
          session.should respond_to(:title)
          session.should respond_to(:description)
          session.should respond_to(:creator_id)
          session.should respond_to(:created_time)
          session.should respond_to(:deleted_time)
          session.should respond_to(:soba_session_id)
          session.should respond_to(:scope)
          session.should respond_to(:participants)
        end
      }.should_not raise_error
    end
    
    it 'can get users list' do
      expect {
        users = @m.users
        users.should be_a(Array)
        users.each do |user|
          user.should be_a(Soba::Mieruka::User)
        end
      }.should_not raise_error
    end
    
    context 'and some sessions exist' do
      before do
        @sessions = @m.sessions
      end
      
      it 'can join the session' do
        pending('No sessions exist!') if @sessions.empty?
        @session = @sessions[0]
        res = @m.join_session(:session_id => @session.id)
      end
    end
    
    it 'can get rooms' do
      rooms = @m.rooms
      rooms.should be_a(Array)
    end
    
    it 'can create and delete a room' do
      rooms = @m.rooms
      rooms.class.should == Array
      n = rooms.size
      
      name = 'room_' + gen_str(10)
      room = @m.create_room(:name => name, :description => 'test room')
      room.name.should == name
      room.description.should == 'test room'
      rooms = @m.rooms
      rooms.size.should == (n + 1)

      expect {
        @m.delete_room(room.id)
      }.should_not raise_error
      @m.rooms.size.should == n
    end
    
    it 'can change its own password' do
      old_password = valid_account[:password]
      new_password = gen_str(16)
      expect {
        @m.change_password(new_password)
        @m.login(valid_account.merge(:password => new_password))
        @m.change_password(old_password)
      }.should_not raise_error
      expect {
        @m.login(valid_account.merge(:password => new_password))
      }.should raise_error
    end
  end
  
end

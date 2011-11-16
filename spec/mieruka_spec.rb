require_relative '../lib/soba/mieruka'

CONFIG = {
  :api_key => 'your_api_key',
  :private_key => 'your_private_key',
  #:version => '1.4'
}

ACCOUNT = {
  :user_name => 'your_soba_mieruka_account',
  :password => 'your_account_password'
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
    res = @m.login(valid_account)
    res.ok?.should be_true
    res = @m.logout
    res.ok?.should be_true
  end
  
  context 'is logged in' do
    before do
      res = @m.login(valid_account)
      res.ok?.should be_true
    end
    
    it 'make a new session' do
      res = @m.create_session(:session_name => 'test', :session_description => 'this is a test')
      res.ok?.should be_true
    end
    
    it 'get the session list' do
      res = @m.sessions
      res.ok?.should be_true
      res.should respond_to(:sessions)
      res.sessions.class.should == Array
    end
    
    it 'can get users list' do
      res = @m.users
      res.ok?.should be_true
      res.should respond_to(:users)
      res.users.class.should == Array
    end
    
    context 'and some sessions exist' do
      before do
        res = @m.sessions
        res.ok?.should be_true
        @sessions = res.sessions
      end
      
      it 'can join the session' do
        pending('No sessions exist!') if @sessions.empty?
        @session = @sessions[0]
        res = @m.join_session(:session_id => @session.id)
      end
    end
    
    it 'can get rooms' do
      res = @m.rooms
      res.ok?.should be_true
      res.should respond_to(:rooms)
      res.rooms.class.should == Array
    end
    
    it 'can create and delete a room' do
      rooms = @m.rooms.rooms
      rooms.class.should == Array
      n = rooms.size
      
      name = 'room_' + gen_str(10)
      res = @m.create_room(:name => name, :description => 'test room')
      res.ok?.should be_true
      res.should respond_to(:room)
      room = res.room
      room.name.should == name
      room.description.should == 'test room'
      rooms = @m.rooms.rooms
      rooms.size.should == (n + 1)

      res = @m.delete_room(room.id)
      res.ok?.should be_true
      @m.rooms.rooms.size.should == n
    end
    
    it 'can change its own password' do
      old_password = valid_account[:password]
      new_password = gen_str(16)
      res = @m.change_password(new_password)
      res.ok?.should be_true
      res = @m.login(valid_account.merge(:password => new_password))
      res.ok?.should be_true
      res = @m.change_password(old_password)
      res.ok?.should be_true
      res = @m.login(valid_account.merge(:password => new_password))
      res.ok?.should be_false
    end
  end
  
end

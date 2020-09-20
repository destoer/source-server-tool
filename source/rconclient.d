module rconclient;


import std.socket;
import std.string;
import std.exception;
import std.algorithm;
import core.stdc.string;


// https://developer.valvesoftware.com/wiki/Source_RCON_Protocol

class RconClient {
	
	this() {
		idCount = 0;
	}


	const int SERVERDATA_AUTH = 3;
	const int SERVERDATA_AUTH_RESPONSE = 2;
	const int SERVERDATA_EXECCOMMAND = 2;
	const int SERVERDATA_RESPONSE_VALUE = 0;

	const int MAX_SIZE = 0x1008;

	struct RconPacket {
		this(byte[] buf) {

			enforce(buf.length >= 10);

			//memcpy(&size,&buf,size.sizeof);
			memcpy(&id,&buf[0],id.sizeof);
			memcpy(&type,&buf[4],type.sizeof);

			// it should have a null term on the end anyways
			// but just in case
			buf[buf.length-1] = '\0'; 

			// make a string from raw bytes!
			resp = fromStringz(cast(char*)&buf[8]).idup;
		}

		//int size; skip size
		int id;
		int type;
		string resp;
	}

	byte[] makePacket(int id, int type, string command) {
		// ok first things first calc the size this will take

		// then alloc a byte buffer and dump in everything 
		//  id , type two null terms  + command
		const int size = cast(int)(10 + command.length); 

		// alloc a buf large enough for this and jam data into it
		// the actual buf needs to be four larger for the size
		auto buf = new byte[size+4];
	
		// this is effectively what the packet actually is
		// before we serialize it
/*
		//int size; 
		int id;
		int type;
		char[] str;
		const char term = '\0';
*/
	

		memcpy(&buf[0],&size,size.sizeof);
		memcpy(&buf[4],&id,id.sizeof);
		memcpy(&buf[8],&type,type.sizeof);

		memcpy(&buf[12],toStringz(command),command.length);
		buf[buf.length-2] = '\0';
		buf[buf.length-1] = '\0';

		return buf;
	}



	bool connect(string server,string port) {
		auto addresses = getAddress(server,port);
		socket = new Socket(AddressFamily.INET,SocketType.STREAM,ProtocolType.TCP);
		socket.connect(addresses[0]);

		return socket.isAlive();
	}

	bool auth(string password) {

		// ok so the server is expecting a SERVERDATA_AUTH packet
		// with a password in the command field
		auto packet = makePacket(++idCount,SERVERDATA_AUTH,password);

		socket.send(packet);

		auto buf = new byte[MAX_SIZE];

		// empty SERVERDATA_RESPONSE_VALUE sent
		readPacket(buf);

		// ok now we will get  SERVERDATA_AUTH_RESPONSE
		readPacket(buf);

		auto reply = new RconPacket(buf);

		return reply.id != -1;
	}

	void readPacket(byte[] buf) {
		byte[4] size_buf;

		int size = 0;

		// .receive will give either how much the buffer can hold
		// or whatever is waiting on the socket
		// however we want a specific ammount of bytes off it
		size_t count = 0;
		while(count != int.sizeof) {
			const auto recv = socket.receive(size_buf[count .. size.sizeof]);
			count += recv;
		}

		memcpy(&size,&size_buf,size.sizeof);


		enforce(size <= MAX_SIZE,format("invalid size: %x",size));
		enforce(buf.length >= size,format("buf is not large enough for: %x",size));

		
		count = 0;
		while(count != size) {
			const auto recv = socket.receive(buf[count .. size]);
			count += recv;
		}
	}

	string sendCommand(string command) {

		// ok now we need to send  SERVERDATA_EXECCOMMAND
		// TODO: cut off commands that are too large
		const auto commandPacket = makePacket(++idCount,SERVERDATA_EXECCOMMAND,command);

		socket.send(commandPacket);

		// ok now we need to verify we dont need more data off this
		// so we will send an extra SERVERDATA_RESPONSE_VALUE packet
		// and keep track of the id when we get this id back off the server
		// we know we are done!

		const auto checkPacket = makePacket(++idCount,SERVERDATA_RESPONSE_VALUE,"");
		const auto doneId = idCount;
		socket.send(checkPacket);


		string resp = "";

		auto buf = new byte[MAX_SIZE];

		while(true) {
			readPacket(buf);

			const auto respPacket = RconPacket(buf);

			// cat resp onto end
			resp = resp ~ respPacket.resp;

			if(respPacket.id == doneId) {
				
				// we will get back an an extra SERVERDATA_RESPONSE_VALUE  packet
				readPacket(buf);

				break;
			}
		}

		return resp;
	}

	~this()
	{
		socket.close();
	}

	Socket socket;

	// we will just use increment ids for packets
	int idCount;
}
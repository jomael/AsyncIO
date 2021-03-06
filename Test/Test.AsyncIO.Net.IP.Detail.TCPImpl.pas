unit Test.AsyncIO.Net.IP.Detail.TCPImpl;
{

  Delphi DUnit Test Case
  ----------------------
  This unit contains a skeleton test case class generated by the Test Case Wizard.
  Modify the generated code to correctly setup and call the methods from the unit 
  being tested.

}

interface

uses
  TestFramework, AsyncIO.Net.IP.Detail.TCPImpl, AsyncIO.Net.IP, IdWinsock2, AsyncIO, NetTestCase,
  EchoTestServer, EchoTestClient;

type
  // Test methods for class TTCPSocketImpl

  TestTTCPSocketImpl = class(TNetTestCase)
  strict private
    FTestServer: IEchoTestServer;
    FService: IOService;
    FTCPSocketImpl: IPStreamSocket;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGetService;
    procedure TestGetProtocol;
    procedure TestGetProtocolIPv4;
    procedure TestGetProtocolIPv6;
    procedure TestGetLocalEndpoint;
    procedure TestGetRemoteEndpoint;
    procedure TestGetSocketHandle;
    procedure TestAsyncConnect;
    procedure TestBind;
    procedure TestConnect;
    procedure TestClose;
    procedure TestShutdown;
    procedure TestAsyncSend;
    procedure TestAsyncReceive;
  end;
  // Test methods for class TTCPAcceptorImpl

  TestTTCPAcceptorImpl = class(TNetTestCase)
  strict private
    FTestClient: IEchoTestClient;
    FService: IOService;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGetService;
    procedure TestGetProtocol;
    procedure TestGetLocalEndpoint;
    procedure TestGetIsOpen;
    procedure TestAsyncAccept;
    procedure TestOpen;
    procedure TestBind;
    procedure TestListen;
    procedure TestClose;
  end;

implementation

uses
  System.SysUtils, AsyncIO.OpResults, System.Threading, IdStack;

procedure TestTTCPSocketImpl.SetUp;
begin
  FTestServer := NewEchoTestServer(7);
  FService := NewIOService();
  FTCPSocketImpl := NewTCPSocket(FService);
end;

procedure TestTTCPSocketImpl.TearDown;
begin
  FTCPSocketImpl := nil;
  FService := nil;
  FTestServer := nil;
end;

procedure TestTTCPSocketImpl.TestGetService;
var
  ReturnValue: IOService;
begin
  ReturnValue := FTCPSocketImpl.GetService;
  CheckSame(FService, ReturnValue);
end;

procedure TestTTCPSocketImpl.TestGetSocketHandle;
begin
  // TODO
end;

procedure TestTTCPSocketImpl.TestGetProtocol;
var
  ReturnValue: IPProtocol;
begin
  ReturnValue := FTCPSocketImpl.GetProtocol;

  CheckEquals(IPProtocol.TCP.Unspecified, ReturnValue);
end;

procedure TestTTCPSocketImpl.TestGetProtocolIPv4;
var
  ReturnValue: IPProtocol;
begin
  FTCPSocketImpl.Bind(Endpoint(IPAddressFamily.v4, 0));

  ReturnValue := FTCPSocketImpl.GetProtocol;

  CheckEquals(IPProtocol.TCP.v4, ReturnValue);
end;

procedure TestTTCPSocketImpl.TestGetProtocolIPv6;
var
  ReturnValue: IPProtocol;
begin
  FTCPSocketImpl.Bind(Endpoint(IPAddressFamily.v6, 0));

  ReturnValue := FTCPSocketImpl.GetProtocol;

  CheckEquals(IPProtocol.TCP.v6, ReturnValue);
end;

procedure TestTTCPSocketImpl.TestGetLocalEndpoint;
var
  ReturnValue: IPEndpoint;
begin
  try
    ReturnValue := FTCPSocketImpl.GetLocalEndpoint;
  except
    on E: Exception do CheckIs(E, EOSError, 'Failed to raise OS error for unbound socket');
  end;

  FTCPSocketImpl.Bind(Endpoint(IPv4Address.Loopback, 0));

  ReturnValue := FTCPSocketImpl.GetLocalEndpoint;

  CheckEquals(IPv4Address.Loopback, ReturnValue.Address, 'Failed to get local endpoint');
end;

procedure TestTTCPSocketImpl.TestGetRemoteEndpoint;
var
  PeerEndpoint: IPEndpoint;
  ReturnValue: IPEndpoint;
begin
  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  FTCPSocketImpl.Connect(PeerEndpoint);

  ReturnValue := FTCPSocketImpl.GetRemoteEndpoint;

  CheckEquals(PeerEndpoint, ReturnValue);
end;

procedure TestTTCPSocketImpl.TestAsyncConnect;
var
  Handler: OpHandler;
  PeerEndpoint: IPEndpoint;
  HandlerExecuted: boolean;
begin
  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult)
    begin
      HandlerExecuted := True;
      CheckEquals(SystemResults.Success, Res, 'AsyncConnect failed');
      CheckEquals(PeerEndpoint, FTCPSocketImpl.RemoteEndpoint, 'Wrong remote endpoint');
    end;

  FTCPSocketImpl.AsyncConnect(PeerEndpoint, Handler);

  FService.Poll;

  CheckTrue(HandlerExecuted, 'Failed to execute connect handler');
end;

procedure TestTTCPSocketImpl.TestBind;
var
  LocalEndpoint: IPEndpoint;
begin
  LocalEndpoint := Endpoint(IPAddressFamily.v4, 0);

  FTCPSocketImpl.Bind(LocalEndpoint);

  CheckEquals(IPProtocol.TCP.v4, FTCPSocketImpl.GetProtocol);

  StartExpectingException(EOSError);

  LocalEndpoint := Endpoint(IPAddressFamily.v6, 0);

  FTCPSocketImpl.Bind(LocalEndpoint);

  StopExpectingException('Failed to raise error on double-bind');
end;

procedure TestTTCPSocketImpl.TestConnect;
var
  PeerEndpoint: IPEndpoint;
  ReturnValue: IPEndpoint;
begin
  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  FTCPSocketImpl.Connect(PeerEndpoint);

  CheckEquals(PeerEndpoint, FTCPSocketImpl.RemoteEndpoint);

  StartExpectingException(EOSError);

  PeerEndpoint := Endpoint(IPv6Address.Loopback, FTestServer.Port);
  FTCPSocketImpl.Connect(PeerEndpoint);

  StopExpectingException('Failed to raise error on double-connect');
end;

procedure TestTTCPSocketImpl.TestClose;
var
  PeerEndpoint: IPEndpoint;
  ReturnValue: IPEndpoint;
begin
  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  FTCPSocketImpl.Connect(PeerEndpoint);

  FTCPSocketImpl.Close;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);
  FTCPSocketImpl.Connect(PeerEndpoint);

  CheckEquals(PeerEndpoint, FTCPSocketImpl.RemoteEndpoint);
end;

procedure TestTTCPSocketImpl.TestShutdown;
var
  PeerEndpoint: IPEndpoint;
  ShutdownFlag: SocketShutdownFlag;
  Data: TBytes;
  Handler: IOHandler;
  HandlerExecuted: boolean;
begin
  SetLength(Data, 42);

  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  FTCPSocketImpl.Connect(PeerEndpoint);


  FTCPSocketImpl.Shutdown(SocketShutdownWrite);

  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult; const BytesTransferred: UInt64)
    begin
      HandlerExecuted := True;
    end;

  try
    FTCPSocketImpl.AsyncSend(Data, Handler);
  except
    on E: Exception do CheckIs(E, EOSError, 'Failed to shutdown write 1');
  end;

  FService.Poll;

  CheckFalse(HandlerExecuted, 'Failed to shutdown write 2');


  FTCPSocketImpl.Shutdown(SocketShutdownRead);

  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult; const BytesTransferred: UInt64)
    begin
      HandlerExecuted := True;
    end;


  try
    FTCPSocketImpl.AsyncReceive(Data, Handler);
  except
    on E: Exception do CheckIs(E, EOSError, 'Failed to shutdown read 1');
  end;

  FService.Poll;

  CheckFalse(HandlerExecuted, 'Failed to shutdown read 2');
end;

procedure TestTTCPSocketImpl.TestAsyncSend;
var
  Data: TBytes;
  PeerEndpoint: IPEndpoint;
  Handler: IOHandler;
  Buffer: MemoryBuffer;
  HandlerExecuted: boolean;
begin
  SetLength(Data, 42);

  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  FTCPSocketImpl.Connect(PeerEndpoint);

  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult; const BytesTransferred: UInt64)
    begin
      HandlerExecuted := True;
      CheckEquals(SystemResults.Success, Res, 'Failed to write data');
      CheckEquals(Length(Data), BytesTransferred, 'Failed to write all data');
    end;

  FTCPSocketImpl.AsyncSend(Data, Handler);

  FService.RunOne;

  CheckTrue(HandlerExecuted, 'Failed to execute write handler');
end;

procedure TestTTCPSocketImpl.TestAsyncReceive;
var
  SrcData: TBytes;
  RecvData: TBytes;
  PeerEndpoint: IPEndpoint;
  Handler: IOHandler;
  Buffer: MemoryBuffer;
  HandlerExecuted: boolean;
begin
  SrcData := GenerateData(42);

  FTestServer.Start;

  PeerEndpoint := Endpoint(IPv4Address.Loopback, FTestServer.Port);

  FTCPSocketImpl.Connect(PeerEndpoint);

  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult; const BytesTransferred: UInt64)
    begin
      HandlerExecuted := True;
      CheckEquals(SystemResults.Success, Res, 'Failed to write data');
      CheckEquals(Length(SrcData), BytesTransferred, 'Failed to write all data');
    end;

  FTCPSocketImpl.AsyncSend(SrcData, Handler);

  FService.RunOne;

  CheckTrue(HandlerExecuted, 'Failed to execute write handler');

  SetLength(RecvData, Length(SrcData));

  // now do actual receive test
  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult; const BytesTransferred: UInt64)
    begin
      HandlerExecuted := True;
      CheckEquals(SystemResults.Success, Res, 'Failed to read data');
      CheckEquals(Length(RecvData), BytesTransferred, 'Failed to read all data');
    end;

  FTCPSocketImpl.AsyncReceive(RecvData, Handler);

  FService.RunOne;

  CheckTrue(HandlerExecuted, 'Failed to execute read handler');

  CheckEqualsMem(SrcData, RecvData, Length(SrcData), 'Read data does not match written data');
end;

{ TestTTCPAcceptorImpl }

procedure TestTTCPAcceptorImpl.SetUp;
begin
  FTestClient := NewEchoTestClient('::1', 7);
  FService := NewIOService();
end;

procedure TestTTCPAcceptorImpl.TearDown;
begin
  FTestClient := nil;
  FService := nil;
end;

procedure TestTTCPAcceptorImpl.TestAsyncAccept;
var
  Data: string;
  TCPAcceptorImpl: IPAcceptor;
  PeerSocket: IPSocket;
  Handler: OpHandler;
  ReturnValue: IFuture<string>;
  HandlerExecuted: boolean;
begin
  Data := 'This is a test string';

  TCPAcceptorImpl := NewTCPAcceptor(FService, Endpoint(IPProtocol.TCP.v6, 7));

  PeerSocket := NewTCPSocket(FService);

  HandlerExecuted := False;
  Handler :=
    procedure(const Res: OpResult)
    begin
      HandlerExecuted := True;
      CheckEquals(SystemResults.Success, Res, 'Failed to accept connection');
      PeerSocket.Close;
    end;

  TCPAcceptorImpl.AsyncAccept(PeerSocket, Handler);

  ReturnValue := FTestClient.ConnectAndSend(Data);

  FService.RunOne;

  try
    ReturnValue.Wait(5000);
    Fail('Client failed to error on socket being closed during sending');
  except
    on E: Exception do
      Check((E is EAggregateException)
        and (EAggregateException(E).InnerExceptions[0] is EIdSocketError)
        and (EIdSocketError(EAggregateException(E).InnerExceptions[0]).LastError = 10054), 'Error while connecting client');
  end;

  CheckTrue(HandlerExecuted, 'Failed to execute accept handler');
end;

procedure TestTTCPAcceptorImpl.TestBind;
var
  Endp: IPEndpoint;
  TCPAcceptorImpl: IPAcceptor;
  TCPSocket: IPSocket;
begin
  Endp := Endpoint(IPProtocol.TCP.v6,  7);

  TCPAcceptorImpl := NewTCPAcceptor(FService);
  TCPAcceptorImpl.Open(Endp.Protocol);
  TCPAcceptorImpl.Bind(Endp);

  TCPSocket := NewTCPSocket(FService);
  try
    TCPSocket.Bind(Endp);
    Fail('Binding socket to same endpoint as acceptor failed to raise exception');
  except
    on E: Exception do CheckIs(E, EOSError, 'Binding socket to same endpoint as acceptor failed to raise OS error');
  end;
end;

procedure TestTTCPAcceptorImpl.TestClose;
var
  Endp: IPEndpoint;
  TCPAcceptorImpl: IPAcceptor;
begin
  Endp := Endpoint(IPAddressFamily.v6,  7);

  TCPAcceptorImpl := NewTCPAcceptor(FService, Endp);

  CheckTrue(TCPAcceptorImpl.IsOpen, 'Close 1');

  TCPAcceptorImpl.Close();

  CheckFalse(TCPAcceptorImpl.IsOpen, 'Close 2');
end;

procedure TestTTCPAcceptorImpl.TestGetIsOpen;
var
  Endp: IPEndpoint;
  TCPAcceptorImpl: IPAcceptor;
begin
  Endp := Endpoint(IPProtocol.TCP.v6,  7);

  TCPAcceptorImpl := NewTCPAcceptor(FService);

  CheckFalse(TCPAcceptorImpl.IsOpen, 'IsOpen 1');

  TCPAcceptorImpl.Open(Endp.Protocol);

  CheckTrue(TCPAcceptorImpl.IsOpen, 'IsOpen 2');
end;

procedure TestTTCPAcceptorImpl.TestGetLocalEndpoint;
var
  Endp: IPEndpoint;
  TCPAcceptorImpl: IPAcceptor;
begin
  Endp := Endpoint(IPAddressFamily.v6,  7);
  TCPAcceptorImpl := NewTCPAcceptor(FService);

  try
    TCPAcceptorImpl.LocalEndpoint;
    Fail('Failed to raise exception on unbound socket');
  except
    on E: Exception do CheckIs(E, EOSError, 'Failed to raise OS error for unbound socket');
  end;

  TCPAcceptorImpl.Bind(Endp);

  CheckEquals(Endp, TCPAcceptorImpl.LocalEndpoint, 'Wrong local endpoint');
end;

procedure TestTTCPAcceptorImpl.TestGetProtocol;
var
  Endp: IPEndpoint;
  TCPAcceptorImpl: IPAcceptor;
begin
  Endp := Endpoint(IPProtocol.TCP.v6,  7);
  TCPAcceptorImpl := NewTCPAcceptor(FService, Endp);

  CheckEquals(Endp.Protocol, TCPAcceptorImpl.Protocol);
end;

procedure TestTTCPAcceptorImpl.TestGetService;
var
  Endp: IPEndpoint;
  TCPAcceptorImpl: IPAcceptor;
begin
  Endp := Endpoint(IPAddressFamily.v6,  7);
  TCPAcceptorImpl := NewTCPAcceptor(FService, Endp);

  CheckSame(FService, TCPAcceptorImpl.Service);
end;

procedure TestTTCPAcceptorImpl.TestListen;
begin
  // TODO - use getsocketopt with SO_ACCEPTCONN
end;

procedure TestTTCPAcceptorImpl.TestOpen;
var
  Protocol: IPProtocol;
  TCPAcceptorImpl: IPAcceptor;
begin
  Protocol := IPProtocol.TCP.v6;
  TCPAcceptorImpl := NewTCPAcceptor(FService);
  TCPAcceptorImpl.Open(Protocol);

  CheckTrue(TCPAcceptorImpl.IsOpen);

  // use
end;

initialization
  // Register any test cases with the test runner
  RegisterTest(TestTTCPSocketImpl.Suite);
  RegisterTest(TestTTCPAcceptorImpl.Suite);
end.


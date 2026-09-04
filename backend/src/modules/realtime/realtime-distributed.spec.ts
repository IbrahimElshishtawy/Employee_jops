import { RealTimeService } from "./realtime.service";

describe("RealTime Multi-Instance WebSocket Event Distribution", () => {
  let instanceA: RealTimeService;
  let instanceB: RealTimeService;
  let mockServerA: any;
  let mockServerB: any;

  beforeEach(() => {
    mockServerA = {
      to: jest.fn().mockReturnValue({ emit: jest.fn() }),
      emit: jest.fn(),
    };
    mockServerB = {
      to: jest.fn().mockReturnValue({ emit: jest.fn() }),
      emit: jest.fn(),
    };

    instanceA = new RealTimeService();
    instanceB = new RealTimeService();

    instanceA.setServer(mockServerA);
    instanceB.setServer(mockServerB);
  });

  afterEach(async () => {
    await instanceA.onModuleDestroy();
    await instanceB.onModuleDestroy();
  });

  it("Cross-Instance Delivery: Event emitted on Instance A is received by connected client room on Instance B", async () => {
    const mockRoomEmitB = jest.fn();
    mockServerB.to.mockReturnValue({ emit: mockRoomEmitB });

    // Instance A emits event to user-42
    instanceA.emitToUser("user-42", "new_notification", {
      id: "notif-999",
      title: "Task Assigned",
    });

    // Verify Instance B's local Socket.IO server forwarded the event to room user:user-42
    expect(mockServerB.to).toHaveBeenCalledWith("user:user-42");
    expect(mockRoomEmitB).toHaveBeenCalledWith("new_notification", {
      id: "notif-999",
      title: "Task Assigned",
    });
  });

  it("Conversation Broadcast: Message emitted on Instance A reaches conversation room on Instance B", async () => {
    const mockConvEmitB = jest.fn();
    mockServerB.to.mockReturnValue({ emit: mockConvEmitB });

    instanceA.emitToConversation("conv-101", "new_message", {
      messageId: "msg-1",
      text: "Front desk shift handover ready",
    });

    expect(mockServerB.to).toHaveBeenCalledWith("conversation:conv-101");
    expect(mockConvEmitB).toHaveBeenCalledWith("new_message", {
      messageId: "msg-1",
      text: "Front desk shift handover ready",
    });
  });

  it("Echo Prevention: Instance A does not double-process its own emitted cluster event", () => {
    const mockRoomEmitA = jest.fn();
    mockServerA.to.mockReturnValue({ emit: mockRoomEmitA });

    instanceA.emitToUser("user-1", "ping", { data: 1 });

    // Room on Instance A should be called once (local delivery), not twice from cluster loopback
    expect(mockRoomEmitA).toHaveBeenCalledTimes(1);
  });
});

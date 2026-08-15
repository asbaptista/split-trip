package com.alexandre.splittrip.dto;

public class JoinTripRequest {
    private String roomCode;
    private String memberName;

    public String getRoomCode() { return roomCode; }
    public void setRoomCode(String roomCode) { this.roomCode = roomCode; }

    public String getMemberName() { return memberName; }
    public void setMemberName(String memberName) { this.memberName = memberName; }
}
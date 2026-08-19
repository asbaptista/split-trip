package com.alexandre.splittrip.dto;

import java.math.BigDecimal;
import java.util.List;

public class AddExpenseRequest {
    private Long tripId;
    private Long paidById;
    private String description;
    private BigDecimal totalAmount;
    private List<Long> involvedMemberIds;

    // Getters and Setters
    public Long getTripId() { return tripId; }
    public void setTripId(Long tripId) { this.tripId = tripId; }
    public Long getPaidById() { return paidById; }
    public void setPaidById(Long paidById) { this.paidById = paidById; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }
    public List<Long> getInvolvedMemberIds() { return involvedMemberIds; }
    public void setInvolvedMemberIds(List<Long> involvedMemberIds) { this.involvedMemberIds = involvedMemberIds; }
}
package com.alexandre.splittrip.dto;

import java.math.BigDecimal;

public record TransferInstruction(
        Long senderId,
        String senderName,
        Long receiverId,
        String receiverName,
        BigDecimal amount
) {}
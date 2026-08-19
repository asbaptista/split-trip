package com.alexandre.splittrip.dto;

import java.math.BigDecimal;

public record MemberBalanceResponse(
        Long memberId,
        String memberName,
        BigDecimal totalPaid,
        BigDecimal totalOwed,
        BigDecimal balance
) {
}

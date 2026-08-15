package com.alexandre.splittrip.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
public class ExpenseSplit {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "expense_id", nullable = false)
    private Expense expense;

    @ManyToOne
    @JoinColumn(name = "member_id", nullable = false)
    private Member member;

    private BigDecimal owedAmount;

    public ExpenseSplit() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Expense getExpense() { return expense; }
    public void setExpense(Expense expense) { this.expense = expense; }
    public Member getMember() { return member; }
    public void setMember(Member member) { this.member = member; }
    public BigDecimal getOwedAmount() { return owedAmount; }
    public void setOwedAmount(BigDecimal owedAmount) { this.owedAmount = owedAmount; }
}
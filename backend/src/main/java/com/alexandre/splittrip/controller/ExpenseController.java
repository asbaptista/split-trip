package com.alexandre.splittrip.controller;

import com.alexandre.splittrip.dto.AddExpenseRequest;
import com.alexandre.splittrip.dto.MemberBalanceResponse;
import com.alexandre.splittrip.dto.TransferInstruction;
import com.alexandre.splittrip.model.Expense;
import com.alexandre.splittrip.service.ExpenseService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Expense addExpense(@RequestBody AddExpenseRequest request) {
        return expenseService.addExpense(request);
    }

    @GetMapping("/trip/{tripId}")
    public ResponseEntity<List<Expense>> getTripExpenses(@PathVariable Long tripId) {
        List<Expense> expenses = expenseService.getExpensesByTrip(tripId);
        return ResponseEntity.ok(expenses);

    }

    @GetMapping("/trip/{tripId}/balances")
    public ResponseEntity<List<MemberBalanceResponse>> getTripBalances(@PathVariable Long tripId) {
        List<MemberBalanceResponse> balances = expenseService.calculateBalances(tripId);
        return ResponseEntity.ok(balances);
    }


    @GetMapping("/trip/{tripId}/settlements")
    public ResponseEntity<List<TransferInstruction>> getTripSettlements(@PathVariable Long tripId) {
        List<TransferInstruction> settlements = expenseService.calculateSettlements(tripId);
        return ResponseEntity.ok(settlements);
    }

}
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
    public ResponseEntity<Expense> addExpense(@RequestBody AddExpenseRequest request) {
        Expense expense = expenseService.addExpense(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(expense);
    }

    @GetMapping("/trip/{tripId}")
    public ResponseEntity<List<Expense>> getTripExpenses(@PathVariable Long tripId) {
        return ResponseEntity.ok(expenseService.getExpensesByTrip(tripId));
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

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteExpense(@PathVariable Long id) {
        expenseService.deleteExpense(id);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Expense> updateExpense(
            @PathVariable Long id,
            @RequestBody AddExpenseRequest request) {
        Expense updatedExpense = expenseService.updateExpense(id, request);
        return ResponseEntity.ok(updatedExpense);
    }
}
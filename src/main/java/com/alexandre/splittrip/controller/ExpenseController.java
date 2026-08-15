package com.alexandre.splittrip.controller;

import com.alexandre.splittrip.dto.AddExpenseRequest;
import com.alexandre.splittrip.model.Expense;
import com.alexandre.splittrip.service.ExpenseService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @PostMapping
    public ResponseEntity<Expense> addExpense(@RequestBody AddExpenseRequest request) {
        Expense newExpense = expenseService.addExpense(
                request.getTripId(),
                request.getPaidById(),
                request.getDescription(),
                request.getTotalAmount(),
                request.getInvolvedMemberIds()
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(newExpense);
    }
}
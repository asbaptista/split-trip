package com.alexandre.splittrip.repository;

import com.alexandre.splittrip.model.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    List<Expense> findByTripIdOrderByExpenseDateDesc(Long tripId);
}
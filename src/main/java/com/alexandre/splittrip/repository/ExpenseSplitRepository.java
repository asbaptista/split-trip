package com.alexandre.splittrip.repository;

import com.alexandre.splittrip.model.ExpenseSplit;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExpenseSplitRepository extends JpaRepository<ExpenseSplit, Long> {
}
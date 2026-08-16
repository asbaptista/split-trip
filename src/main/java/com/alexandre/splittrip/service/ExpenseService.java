package com.alexandre.splittrip.service;

import com.alexandre.splittrip.model.Expense;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.alexandre.splittrip.exception.ResourceNotFoundException;
import com.alexandre.splittrip.model.Expense;
import com.alexandre.splittrip.model.ExpenseSplit;
import com.alexandre.splittrip.model.Member;
import com.alexandre.splittrip.model.Trip;
import com.alexandre.splittrip.repository.ExpenseRepository;
import com.alexandre.splittrip.repository.ExpenseSplitRepository;
import com.alexandre.splittrip.repository.MemberRepository;
import com.alexandre.splittrip.repository.TripRepository;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Service
public class ExpenseService {

    private final ExpenseRepository expenseRepository;
    private final ExpenseSplitRepository splitRepository;
    private final TripRepository tripRepository;
    private final MemberRepository memberRepository;

    public ExpenseService(ExpenseRepository expenseRepository,
                          ExpenseSplitRepository splitRepository,
                          TripRepository tripRepository,
                          MemberRepository memberRepository) {
        this.expenseRepository = expenseRepository;
        this.splitRepository = splitRepository;
        this.tripRepository = tripRepository;
        this.memberRepository = memberRepository;
    }

    @Transactional
    public Expense addExpense(Long tripId, Long paidById, String description, BigDecimal totalAmount, List<Long> involvedMemberIds) {
        if (involvedMemberIds.isEmpty()) {
            throw new ResourceNotFoundException("A despesa tem de ser dividida por pelo menos uma pessoa.");
        }

        Trip trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new ResourceNotFoundException("Viagem não encontrada"));

        Member paidBy = memberRepository.findById(paidById)
                .orElseThrow(() -> new ResourceNotFoundException("Membro pagador não encontrado"));

        // 1. Criar e guardar a Despesa
        Expense expense = new Expense();
        expense.setTrip(trip);
        expense.setPaidBy(paidBy);
        expense.setDescription(description);
        expense.setTotalAmount(totalAmount);
        Expense savedExpense = expenseRepository.save(expense);

        // 2. Procurar todos os membros envolvidos numa só query SQL
        List<Member> involvedMembers = memberRepository.findAllById(involvedMemberIds);

        // 3. Matemática com acerto de cêntimos
        BigDecimal numberOfPeople = new BigDecimal(involvedMembers.size());
        BigDecimal baseSplit = totalAmount.divide(numberOfPeople, 2, RoundingMode.FLOOR);
        BigDecimal remainder = totalAmount.subtract(baseSplit.multiply(numberOfPeople));

        // 4. Lógica de atribuição do resto dos cêntimos
        boolean payerIsInvolved = involvedMembers.stream()
                .anyMatch(m -> m.getId().equals(paidBy.getId()));

        List<ExpenseSplit> splits = new ArrayList<>();
        for (int i = 0; i < involvedMembers.size(); i++) {
            Member member = involvedMembers.get(i);

            boolean getsRemainder = payerIsInvolved
                    ? member.getId().equals(paidBy.getId())
                    : (i == 0);

            BigDecimal amountForThisMember = getsRemainder ? baseSplit.add(remainder) : baseSplit;

            ExpenseSplit split = new ExpenseSplit();
            split.setExpense(savedExpense);
            split.setMember(member);
            split.setOwedAmount(amountForThisMember);

            splits.add(split);
        }

        // 5. Guardar todas as fatias de uma assentada
        splitRepository.saveAll(splits);

        return savedExpense;
    }

    public List<Expense> getExpensesByTrip(Long tripId) {
        return expenseRepository.findByTripIdOrderByExpenseDateDesc(tripId);
    }


}
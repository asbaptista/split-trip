package com.alexandre.splittrip.service;

import com.alexandre.splittrip.dto.AddExpenseRequest;
import com.alexandre.splittrip.dto.MemberBalanceResponse;
import com.alexandre.splittrip.dto.TransferInstruction;
import com.alexandre.splittrip.exception.ResourceNotFoundException;
import com.alexandre.splittrip.model.Expense;
import com.alexandre.splittrip.model.ExpenseSplit;
import com.alexandre.splittrip.model.Member;
import com.alexandre.splittrip.model.Trip;
import com.alexandre.splittrip.repository.ExpenseRepository;
import com.alexandre.splittrip.repository.ExpenseSplitRepository;
import com.alexandre.splittrip.repository.MemberRepository;
import com.alexandre.splittrip.repository.TripRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

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
    public Expense addExpense(AddExpenseRequest request) {
        if (request.getSplitAmongMemberIds() == null || request.getSplitAmongMemberIds().isEmpty()) {
            throw new ResourceNotFoundException("A despesa tem de ser dividida por pelo menos uma pessoa.");
        }

        Trip trip = tripRepository.findById(request.getTripId())
                .orElseThrow(() -> new ResourceNotFoundException("Viagem não encontrada"));

        Member paidBy = memberRepository.findById(request.getPaidById())
                .orElseThrow(() -> new ResourceNotFoundException("Membro pagador não encontrado"));

        // 1. Criar e guardar a Despesa
        Expense expense = new Expense();
        expense.setTrip(trip);
        expense.setPaidBy(paidBy);
        expense.setDescription(request.getDescription());
        expense.setTotalAmount(request.getTotalAmount());
        expense.setExpenseDate(LocalDateTime.now());
        Expense savedExpense = expenseRepository.save(expense);

        // 2. Procurar todos os membros envolvidos numa só query SQL
        List<Member> involvedMembers = memberRepository.findAllById(request.getSplitAmongMemberIds());

        if (involvedMembers.size() != request.getSplitAmongMemberIds().size()) {
            throw new ResourceNotFoundException("Um ou mais membros selecionados não foram encontrados.");
        }

        // 3. Matemática com acerto de cêntimos
        BigDecimal numberOfPeople = new BigDecimal(involvedMembers.size());
        BigDecimal baseSplit = request.getTotalAmount().divide(numberOfPeople, 2, RoundingMode.FLOOR);
        BigDecimal remainder = request.getTotalAmount().subtract(baseSplit.multiply(numberOfPeople));

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

    public List<MemberBalanceResponse> calculateBalances(Long tripId) {
        tripRepository.findById(tripId)
                .orElseThrow(() -> new ResourceNotFoundException("Viagem não encontrada"));

        List<Member> members = memberRepository.findByTripId(tripId);
        List<Expense> expenses = expenseRepository.findByTripIdOrderByExpenseDateDesc(tripId);

        Map<Long, BigDecimal> paidMap = new HashMap<>();
        Map<Long, BigDecimal> owedMap = new HashMap<>();

        for (Member m : members) {
            paidMap.put(m.getId(), BigDecimal.ZERO);
            owedMap.put(m.getId(), BigDecimal.ZERO);
        }

        for (Expense expense : expenses) {
            Long payerId = expense.getPaidBy().getId();

            if (paidMap.containsKey(payerId)) {
                paidMap.put(payerId, paidMap.get(payerId).add(expense.getTotalAmount()));
            }

            for (ExpenseSplit split : expense.getSplits()) {
                Long memberId = split.getMember().getId();
                if (owedMap.containsKey(memberId)) {
                    owedMap.put(memberId, owedMap.get(memberId).add(split.getOwedAmount()));
                }
            }
        }

        List<MemberBalanceResponse> balances = new ArrayList<>();
        for (Member member : members) {
            BigDecimal totalPaid = paidMap.getOrDefault(member.getId(), BigDecimal.ZERO);
            BigDecimal totalOwed = owedMap.getOrDefault(member.getId(), BigDecimal.ZERO);
            BigDecimal balance = totalPaid.subtract(totalOwed);

            balances.add(new MemberBalanceResponse(
                    member.getId(),
                    member.getName(),
                    totalPaid,
                    totalOwed,
                    balance
            ));
        }
        return balances;
    }

    public List<TransferInstruction> calculateSettlements(Long tripId) {
        List<MemberBalanceResponse> balances = calculateBalances(tripId);

        List<MemberBalanceResponse> debtors = new ArrayList<>();
        List<MemberBalanceResponse> creditors = new ArrayList<>();

        for (MemberBalanceResponse b : balances) {
            if (b.balance().compareTo(BigDecimal.ZERO) < 0) {
                debtors.add(b);
            } else if (b.balance().compareTo(BigDecimal.ZERO) > 0) {
                creditors.add(b);
            }
        }

        List<TransferInstruction> transfers = new ArrayList<>();
        int i = 0;
        int j = 0;

        while (i < debtors.size() && j < creditors.size()) {
            MemberBalanceResponse debtor = debtors.get(i);
            MemberBalanceResponse creditor = creditors.get(j);

            BigDecimal debtAmount = debtor.balance().abs();
            BigDecimal creditAmount = creditor.balance();

            BigDecimal transferAmount = debtAmount.min(creditAmount);

            transfers.add(new TransferInstruction(
                    debtor.memberId(),
                    debtor.memberName(),
                    creditor.memberId(),
                    creditor.memberName(),
                    transferAmount
            ));

            BigDecimal newDebtBalance = debtAmount.subtract(transferAmount);
            BigDecimal newCreditBalance = creditAmount.subtract(transferAmount);

            if (newDebtBalance.compareTo(BigDecimal.ZERO) == 0) {
                i++;
            } else {
                debtors.set(i, new MemberBalanceResponse(debtor.memberId(), debtor.memberName(), debtor.totalPaid(), debtor.totalOwed(), newDebtBalance.negate()));
            }

            if (newCreditBalance.compareTo(BigDecimal.ZERO) == 0) {
                j++;
            } else {
                creditors.set(j, new MemberBalanceResponse(creditor.memberId(), creditor.memberName(), creditor.totalPaid(), creditor.totalOwed(), newCreditBalance));
            }
        }

        return transfers;
    }

    @Transactional
    public void deleteExpense(Long expenseId) {
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new ResourceNotFoundException("Despesa não encontrada"));
        expenseRepository.delete(expense);
    }   
}
package com.alexandre.splittrip.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.alexandre.splittrip.model.Member;
import java.util.List;

public interface MemberRepository extends JpaRepository<Member, Long> {
    List<Member> findByTripId(Long tripId);
}